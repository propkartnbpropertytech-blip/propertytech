<?php
$sessionId = isset($_GET['sessionId']) ? $_GET['sessionId'] : '';
$propertyId = isset($_GET['propertyId']) ? $_GET['propertyId'] : '';

$seoTitle = 'PropKart - Premium Property Management Software & CRM';
$seoDescription = 'Find your dream home, manage property listings, and connect with top agents and builders effortlessly with PropKart.';
$seoImage = 'https://propkart.nbpropertytech.com/assets/logo.png';
$seoUrl = 'https://propkart.nbpropertytech.com/share/' . $sessionId;
$structuredData = null;

if ($propertyId) {
    $seoUrl .= '/property/' . $propertyId;
}

if (!empty($sessionId)) {
    // Fetch live session details from backend API
    $apiUrl = 'https://prop-kart-backend.vercel.app/api/v1/share-sessions/public/' . $sessionId;
    
    // Set timeout to avoid blocking page load
    $opts = [
        'http' => [
            'method' => 'GET',
            'header' => "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36\r\n",
            'timeout' => 3
        ]
    ];
    $context = stream_context_create($opts);
    
    $response = @file_get_contents($apiUrl, false, $context);
    if ($response) {
        $apiRes = json_decode($response, true);
        if ($apiRes && isset($apiRes['success']) && $apiRes['success'] && isset($apiRes['data'])) {
            $data = $apiRes['data'];
            $agent = isset($data['agent']) ? $data['agent'] : null;
            $properties = isset($data['properties']) ? $data['properties'] : [];
            $agentName = ($agent && isset($agent['full_name'])) ? $agent['full_name'] : 'PropKart Agent';
            
            if ($propertyId && !empty($properties)) {
                $p = null;
                foreach ($properties as $prop) {
                    if (isset($prop['id']) && $prop['id'] === $propertyId) {
                        $p = $prop;
                        break;
                    }
                }
                
                if ($p) {
                    $config = isset($p['configuration_name']) ? $p['configuration_name'] : ((isset($p['bedrooms']) ? $p['bedrooms'] : '-') . ' BHK');
                    $area = isset($p['area_name']) ? $p['area_name'] : '';
                    $city = isset($p['city_name']) ? $p['city_name'] : '';
                    $priceVal = isset($p['price']) ? floatval($p['price']) : null;
                    
                    $priceStr = 'Price on Request';
                    if ($priceVal) {
                        if ($priceVal >= 10000000) {
                            $priceStr = '₹' . number_format($priceVal / 10000000, 2) . ' Cr';
                        } else if ($priceVal >= 100000) {
                            $priceStr = '₹' . number_format($priceVal / 100000, 2) . ' L';
                        } else {
                            $priceStr = '₹' . number_format($priceVal);
                        }
                    }
                    
                    $seoTitle = $config . ' in ' . $area . ' | ' . $priceStr . ' - PropKart';
                    $seoDescription = isset($p['description']) ? $p['description'] : ('Check out this premium ' . $config . ' in ' . $area . ' shared by ' . $agentName . ' via PropKart.');
                    
                    if (isset($p['images']) && is_array($p['images']) && !empty($p['images'])) {
                        $seoImage = $p['images'][0];
                    }

                    // Structured Data (JSON-LD)
                    $structuredData = [
                        "@context" => "https://schema.org",
                        "@type" => (isset($p['property_type_name']) && strpos(strtolower($p['property_type_name']), 'apartment') !== false) ? 'Apartment' : 'SingleFamilyResidence',
                        "name" => $config . ' in ' . $area,
                        "description" => $seoDescription,
                        "image" => $seoImage,
                        "url" => $seoUrl,
                        "address" => [
                          "@type" => "PostalAddress",
                          "addressLocality" => $area,
                          "addressRegion" => $city,
                          "addressCountry" => "IN"
                        ]
                    ];

                    if ($priceVal) {
                        $structuredData["offers"] = [
                          "@type" => "Offer",
                          "priceCurrency" => "INR",
                          "price" => $priceVal,
                          "priceValidUntil" => date('Y-m-d', strtotime('+30 days')),
                          "availability" => "https://schema.org/InStock",
                          "seller" => [
                            "@type" => "RealEstateAgent",
                            "name" => $agentName,
                            "telephone" => ($agent && isset($agent['mobile'])) ? $agent['mobile'] : ''
                          ]
                        ];
                    }
                }
            } else {
                $seoTitle = 'Shortlisted Properties | Shared by ' . $agentName . ' - PropKart';
                if (!empty($properties)) {
                    $areas = array_unique(array_filter(array_map(function($pr) { return isset($pr['area_name']) ? $pr['area_name'] : ''; }, $properties)));
                    $seoDescription = 'Review this exclusive shortlist of premium properties located in ' . implode(', ', array_slice($areas, 0, 3)) . ', curated by agent ' . $agentName . ' on PropKart.';
                } else {
                    $seoDescription = 'View shortlisted properties curated for you by ' . $agentName . ' on PropKart.';
                }
            }
        }
    }
}

// Read index.html local file
$indexPath = 'index.html';
if (file_exists($indexPath)) {
    $html = file_get_contents($indexPath);
    
    // Replace title
    $html = preg_replace('/<title>.*?<\/title>/i', '<title>' . htmlspecialchars($seoTitle) . '</title>', $html);
    // Remove default description meta tag if present
    $html = preg_replace('/<meta name="description" content=".*?">/i', '', $html);

    // Prepare and format tags
    $seoTags = '
  <meta name="description" content="' . htmlspecialchars($seoDescription) . '">
  <meta property="og:title" content="' . htmlspecialchars($seoTitle) . '">
  <meta property="og:description" content="' . htmlspecialchars($seoDescription) . '">
  <meta property="og:image" content="' . htmlspecialchars($seoImage) . '">
  <meta property="og:url" content="' . htmlspecialchars($seoUrl) . '">
  <meta property="og:type" content="website">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="' . htmlspecialchars($seoTitle) . '">
  <meta name="twitter:description" content="' . htmlspecialchars($seoDescription) . '">
  <meta name="twitter:image" content="' . htmlspecialchars($seoImage) . '">
  <link rel="canonical" href="' . htmlspecialchars($seoUrl) . '">
  <meta name="robots" content="index, follow">
';

    if ($structuredData) {
        $seoTags .= '
  <script type="application/ld+json">
  ' . json_encode($structuredData, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . '
  </script>';
    }

    // Inject before </head>
    $html = str_replace('</head>', $seoTags . "\n</head>", $html);
    
    header('Content-Type: text/html; charset=utf-8');
    echo $html;
} else {
    header("HTTP/1.1 404 Not Found");
    echo 'Site index.html not found.';
}
