const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');

// Helper to fetch data via Node.js http/https module without external dependencies
function fetchUrl(url) {
  return new Promise((resolve, reject) => {
    const client = url.startsWith('https') ? https : http;
    client.get(url, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', (err) => {
      reject(err);
    });
  });
}

module.exports = async (req, res) => {
  const { sessionId, propertyId } = req.query;

  let seoTitle = 'PropKart - Premium Property Management Software & CRM';
  let seoDescription = 'Find your dream home, manage property listings, and connect with top agents and builders effortlessly with PropKart.';
  let seoImage = 'https://propkart.nbpropertytech.com/assets/logo.png';
  let seoUrl = `https://propkart.nbpropertytech.com/share/${sessionId}`;
  let structuredData = null;

  if (propertyId) {
    seoUrl += `/property/${propertyId}`;
  }

  // 1. Fetch live share session details from backend API
  try {
    const apiRes = await fetchUrl(`http://200.234.36.120:5001/api/v1/share-sessions/public/${sessionId}`);
    
    if (apiRes && apiRes.success && apiRes.data) {
      const { agent, properties } = apiRes.data;
      const agentName = agent?.full_name || 'PropKart Agent';
      
      if (propertyId && properties) {
        const p = properties.find(prop => prop.id === propertyId);
        if (p) {
          const config = p.configuration_name || `${p.bedrooms || '-'} BHK`;
          const rawArea = p.area_name || p.areaName || (p.area && typeof p.area === 'object' ? p.area.area_name || p.area.name : (p.area || p.landmark || p.address || p.city_name || p.cityName || ''));
          const area = (rawArea && String(rawArea).toUpperCase() !== 'N/A') ? rawArea : '';
          const titleArea = area ? ` in ${area}` : '';
          const city = p.city_name || p.cityName || (p.city && typeof p.city === 'object' ? p.city.city_name || p.city.name : '') || '';
          const priceVal = p.price ? parseFloat(p.price) : null;
          
          let priceStr = 'Price on Request';
          if (priceVal) {
            if (priceVal >= 10000000) {
              priceStr = `₹${(priceVal / 10000000).toFixed(2)} Cr`;
            } else if (priceVal >= 100000) {
              priceStr = `₹${(priceVal / 100000).toFixed(2)} L`;
            } else {
              priceStr = `₹${priceVal.toLocaleString('en-IN')}`;
            }
          }
          
          seoTitle = `${config}${titleArea} | ${priceStr} - PropKart`;
          seoDescription = p.description || `Check out this premium ${config}${titleArea} shared by ${agentName} via PropKart.`;
          
          if (p.images && p.images.length > 0) {
            seoImage = p.images[0];
          }

          // Structured Data (JSON-LD) for SingleFamilyResidence / Apartment
          structuredData = {
            "@context": "https://schema.org",
            "@type": p.property_type_name && p.property_type_name.toLowerCase().includes('apartment') ? 'Apartment' : 'SingleFamilyResidence',
            "name": `${config} in ${area}`,
            "description": seoDescription,
            "image": seoImage,
            "url": seoUrl,
            "address": {
              "@type": "PostalAddress",
              "addressLocality": area,
              "addressRegion": city,
              "addressCountry": "IN"
            }
          };

          if (priceVal) {
            structuredData.offers = {
              "@type": "Offer",
              "priceCurrency": "INR",
              "price": priceVal,
              "priceValidUntil": new Date(Date.now() + 1000 * 60 * 60 * 24 * 30).toISOString().split('T')[0], // 30 days from now
              "availability": "https://schema.org/InStock",
              "seller": {
                "@type": "RealEstateAgent",
                "name": agentName,
                "telephone": agent?.mobile || ''
              }
            };
          }
        }
      } else {
        seoTitle = `Shortlisted Properties | Shared by ${agentName} - PropKart`;
        if (properties && properties.length > 0) {
          const areas = [...new Set(properties.map(p => p.area_name).filter(Boolean))];
          seoDescription = `Review this exclusive shortlist of premium properties located in ${areas.slice(0, 3).join(', ')}, curated by agent ${agentName} on PropKart.`;
        } else {
          seoDescription = `View shortlisted properties curated for you by ${agentName} on PropKart.`;
        }
      }
    }
  } catch (err) {
    console.error('Error fetching share metadata:', err);
  }

  // 2. Read the built index.html from workspace output and inject tags
  try {
    const indexPath = path.join(process.cwd(), 'build/web/index.html');
    
    if (fs.existsSync(indexPath)) {
      let html = fs.readFileSync(indexPath, 'utf8');

      // Strip pre-existing generic tags
      html = html.replace(/<title>.*?<\/title>/i, `<title>${seoTitle}</title>`);
      html = html.replace(/<meta name="description" content=".*?">/i, '');

      // Prepare new SEO and Open Graph tags
      let seoTags = `
  <meta name="description" content="${seoDescription}">
  <meta property="og:title" content="${seoTitle}">
  <meta property="og:description" content="${seoDescription}">
  <meta property="og:image" content="${seoImage}">
  <meta property="og:url" content="${seoUrl}">
  <meta property="og:type" content="website">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${seoTitle}">
  <meta name="twitter:description" content="${seoDescription}">
  <meta name="twitter:image" content="${seoImage}">
  <link rel="canonical" href="${seoUrl}">
  <meta name="robots" content="index, follow">
      `;

      // Inject structured JSON-LD schema if available
      if (structuredData) {
        seoTags += `\n  <script type="application/ld+json">\n  ${JSON.stringify(structuredData, null, 2)}\n  </script>`;
      }

      // Inject before </head>
      html = html.replace('</head>', `${seoTags}\n</head>`);

      res.setHeader('Content-Type', 'text/html');
      return res.status(200).send(html);
    } else {
      return res.status(404).send('Deploy build index.html not found. Make sure web is built.');
    }
  } catch (err) {
    console.error('Error serving preview index:', err);
    return res.status(500).send('Internal Server Error');
  }
};
