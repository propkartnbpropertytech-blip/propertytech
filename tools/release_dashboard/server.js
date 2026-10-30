const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn, exec } = require('child_process');

const PORT = process.env.PORT || 5050;
const REPO_ROOT = path.resolve(__dirname, '..', '..');
const PUBLIC_DIR = path.join(__dirname, 'public');

// Helper to execute commands with Promises
function runCmd(cmd, cwd = REPO_ROOT) {
  return new Promise((resolve) => {
    exec(cmd, { cwd, maxBuffer: 10 * 1024 * 1024 }, (error, stdout, stderr) => {
      resolve({
        success: !error,
        code: error ? (error.code || 1) : 0,
        stdout: (stdout || '').trim(),
        stderr: (stderr || '').trim(),
      });
    });
  });
}

// Read version from pubspec.yaml
function getPubspecVersion() {
  try {
    const pubspecPath = path.join(REPO_ROOT, 'pubspec.yaml');
    if (fs.existsSync(pubspecPath)) {
      const content = fs.readFileSync(pubspecPath, 'utf8');
      const match = content.match(/^version:\s*([^\s+]+)/m);
      if (match) return match[1];
    }
  } catch (_) {}
  return '1.1.2';
}

// Check local Linux package status
function getLinuxBundleInfo() {
  try {
    const bundlePath = path.join(REPO_ROOT, 'PropKart-linux-x86_64.tar.gz');
    if (fs.existsSync(bundlePath)) {
      const stat = fs.statSync(bundlePath);
      const sizeMB = (stat.size / (1024 * 1024)).toFixed(2);
      return {
        exists: true,
        path: 'PropKart-linux-x86_64.tar.gz',
        sizeMB: `${sizeMB} MB`,
        updatedAt: stat.mtime.toISOString(),
      };
    }
  } catch (_) {}
  return { exists: false, sizeMB: '0 MB', path: null, updatedAt: null };
}

// Active build process tracker
let activeBuild = null;

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);

  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // --- API: Overall Status ---
  if (url.pathname === '/api/status' && req.method === 'GET') {
    const [branchRes, shaRes, logRes, statusRes, aheadRes, ghRunsRes] = await Promise.all([
      runCmd('git branch --show-current'),
      runCmd('git rev-parse --short HEAD'),
      runCmd('git log -1 --pretty=%B'),
      runCmd('git status --porcelain'),
      runCmd('git rev-list --count origin/main..HEAD'),
      runCmd('gh run list --limit 8 --json databaseId,name,status,conclusion,headBranch,headSha,event,createdAt,updatedAt,url'),
    ]);

    const version = getPubspecVersion();
    let githubRuns = [];
    if (ghRunsRes.success && ghRunsRes.stdout) {
      try {
        githubRuns = JSON.parse(ghRunsRes.stdout);
      } catch (_) {}
    }

    const dirtyLines = statusRes.stdout ? statusRes.stdout.split('\n').filter(Boolean) : [];

    const data = {
      branch: branchRes.stdout || 'main',
      commitSha: shaRes.stdout || 'HEAD',
      commitMessage: (logRes.stdout || '').split('\n')[0],
      unpushedCount: parseInt(aheadRes.stdout || '0', 10) || 0,
      isClean: dirtyLines.length === 0,
      dirtyFilesCount: dirtyLines.length,
      version: version,
      tag: `v${version}`,
      linuxBundle: getLinuxBundleInfo(),
      isBuildingLinux: activeBuild !== null,
      githubRuns,
    };

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(data));
    return;
  }

  // --- API: Workflow Run Details ---
  if (url.pathname.startsWith('/api/runs/') && req.method === 'GET') {
    const runId = url.pathname.replace('/api/runs/', '');
    const details = await runCmd(`gh run view ${runId} --json jobs,status,conclusion,url,name`);
    if (details.success) {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(details.stdout);
    } else {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: details.stderr || 'Failed to fetch run details' }));
    }
    return;
  }

  // --- API: Push to GitHub Main ---
  if (url.pathname === '/api/push-main' && req.method === 'POST') {
    const version = getPubspecVersion();
    const tag = `v${version}`;

    // Push main and sync tag
    const pushRes = await runCmd('git push origin main');
    const tagRes = await runCmd(`git tag -f ${tag} && git push origin -f ${tag}`);

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      success: pushRes.success && tagRes.success,
      pushOutput: pushRes.stdout || pushRes.stderr,
      tagOutput: tagRes.stdout || tagRes.stderr,
    }));
    return;
  }

  // --- API: Upload Local Linux Package to GitHub Release ---
  if (url.pathname === '/api/upload-linux' && req.method === 'POST') {
    const bundle = getLinuxBundleInfo();
    if (!bundle.exists) {
      res.writeHead(400, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'PropKart-linux-x86_64.tar.gz does not exist. Build it first!' }));
      return;
    }

    const version = getPubspecVersion();
    const tag = `v${version}`;
    const uploadRes = await runCmd(`gh release upload ${tag} PropKart-linux-x86_64.tar.gz --clobber`);

    res.writeHead(uploadRes.success ? 200 : 500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      success: uploadRes.success,
      output: uploadRes.stdout || uploadRes.stderr,
      tag,
      downloadUrl: `https://github.com/propkartnbpropertytech-blip/propertytech/releases/latest/download/PropKart-linux-x86_64.tar.gz`
    }));
    return;
  }

  // --- API: Live Build Linux with SSE Streaming ---
  if (url.pathname === '/api/build-linux-stream' && req.method === 'GET') {
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    });

    const sendEvent = (type, data) => {
      res.write(`data: ${JSON.stringify({ type, data })}\n\n`);
    };

    if (activeBuild) {
      sendEvent('log', '⚠️ A build is already in progress...\n');
      return;
    }

    sendEvent('start', '🚀 Starting Local Linux Build in WSL2 Ubuntu...\n');

    // Build command inside WSL2 Ubuntu
    const wslCommand = [
      'export PATH="/home/dell/flutter/bin:$PATH"',
      'cd /mnt/c/Users/DELL/Desktop/NB/propertytech',
      'echo "==> Flutter Linux Toolchain:"',
      'flutter --version | head -n 2',
      'echo "==> Enabling Linux Desktop..."',
      'flutter config --enable-linux-desktop',
      'echo "==> Getting Dependencies..."',
      'flutter pub get',
      'echo "==> Compiling Release Binary (flutter build linux)..."',
      'flutter build linux --release --dart-define=APP_ENV=production',
      'echo "==> Packaging Distribution Tarball..."',
      'if [ -d build/linux/x64/release/bundle ]; then tar -czvf PropKart-linux-x86_64.tar.gz -C build/linux/x64/release/bundle . ; elif [ -d build/bundle ]; then tar -czvf PropKart-linux-x86_64.tar.gz -C build/bundle . ; fi',
      'ls -lh PropKart-linux-x86_64.tar.gz'
    ].join(' && ');

    activeBuild = spawn('wsl.exe', ['-d', 'Ubuntu', '-e', 'bash', '-c', wslCommand]);

    activeBuild.stdout.on('data', (chunk) => {
      sendEvent('log', chunk.toString());
    });

    activeBuild.stderr.on('data', (chunk) => {
      sendEvent('log', chunk.toString());
    });

    activeBuild.on('close', (code) => {
      activeBuild = null;
      const bundle = getLinuxBundleInfo();
      sendEvent('done', {
        code,
        success: code === 0,
        bundle,
      });
      res.end();
    });

    req.on('close', () => {
      // client disconnected
    });

    return;
  }

  // --- Static Assets Serving ---
  let filePath = path.join(PUBLIC_DIR, url.pathname === '/' ? 'index.html' : url.pathname);
  if (!fs.existsSync(filePath)) {
    filePath = path.join(PUBLIC_DIR, 'index.html');
  }

  const ext = path.extname(filePath).toLowerCase();
  const mimeTypes = {
    '.html': 'text/html',
    '.js': 'application/javascript',
    '.css': 'text/css',
    '.json': 'application/json',
    '.png': 'image/png',
    '.svg': 'image/svg+xml',
  };

  const contentType = mimeTypes[ext] || 'text/plain';
  fs.readFile(filePath, (err, content) => {
    if (err) {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('File Not Found');
    } else {
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content);
    }
  });
});

server.listen(PORT, () => {
  console.log(`===================================================`);
  console.log(`🚀 PropKart Release Dashboard & CI Control Center`);
  console.log(`🌐 Live at: http://localhost:${PORT}`);
  console.log(`📁 Target Repo: ${REPO_ROOT}`);
  console.log(`===================================================`);
});
