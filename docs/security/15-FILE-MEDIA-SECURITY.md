# 15 — FILE & MEDIA UPLOAD SECURITY

## 1. Attack Vectors on Upload Pipelines

Unrestricted file uploads represent severe application risks:
1. **Malicious Executables**: Spoofing `.php`, `.sh`, or `.exe` as image extensions.
2. **SVG XSS**: Embedding `<script>` tags inside SVG vector files.
3. **Path Traversal**: Filenames containing `../` or `..\` overwriting system files.
4. **Denial of Service**: Giant file payloads exhausting memory or disk.

---

## 2. Server-Side File Hardening (`fileMagic.js`)

PropKart validates uploads based on **binary magic bytes** rather than client-reported MIME headers or file extensions:

```javascript
export function detectFileType(buffer) {
    if (!buffer || buffer.length < 4) return null;
    // JPEG: FF D8 FF
    if (buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) {
        return { ext: "jpg", mime: "image/jpeg" };
    }
    // PNG: 89 50 4E 47
    if (buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4e && buffer[3] === 0x47) {
        return { ext: "png", mime: "image/png" };
    }
    // WebP: RIFF ... WEBP
    if (buffer.toString("ascii", 0, 4) === "RIFF" && buffer.toString("ascii", 8, 12) === "WEBP") {
        return { ext: "webp", mime: "image/webp" };
    }
    // PDF: %PDF
    if (buffer.toString("ascii", 0, 4) === "%PDF") {
        return { ext: "pdf", mime: "application/pdf" };
    }
    return null;
}
```

---

## 3. Upload Security Policies

1. **Strict Allowed MIME Types**:
   - `image/jpeg`, `image/png`, `image/webp`, `application/pdf`.
   - SVG (`image/svg+xml`) is explicitly blocked to prevent stored Cross-Site Scripting.
2. **Filename Sanitization**:
   - Filenames are sanitized, stripping `..`, `/`, `\`, and non-alphanumeric characters.
   - Internal storage uses randomly generated UUID keys, eliminating direct path traversal attacks.
3. **Strict Size Limits**:
   - Property media & profile uploads capped at 10MB per file.
4. **Signed CDN Delivery**:
   - Media storage is delegated to Cloudinary via server-signed upload signatures.
   - Private documents use access-controlled signed URLs with expiration.
