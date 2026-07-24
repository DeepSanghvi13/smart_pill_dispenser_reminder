function parseUserAgent(uaString) {
  const ua = String(uaString || '').toLowerCase();
  
  let device = 'Desktop';
  if (ua.includes('mobi') || ua.includes('iphone') || ua.includes('android')) {
    device = 'Mobile';
  } else if (ua.includes('ipad') || ua.includes('tablet')) {
    device = 'Tablet';
  }

  let browser = 'Other';
  if (ua.includes('edg/') || ua.includes('edge')) {
    browser = 'Edge';
  } else if (ua.includes('firefox') && !ua.includes('seamonkey')) {
    browser = 'Firefox';
  } else if (ua.includes('opr/') || ua.includes('opera')) {
    browser = 'Opera';
  } else if (ua.includes('chrome') && !ua.includes('chromium')) {
    browser = 'Chrome';
  } else if (ua.includes('safari') && !ua.includes('chrome') && !ua.includes('chromium')) {
    browser = 'Safari';
  } else if (ua.includes('msie') || ua.includes('trident')) {
    browser = 'IE';
  } else if (ua.includes('postman')) {
    browser = 'Postman';
  } else if (ua.includes('dart') || ua.includes('flutter')) {
    browser = 'Flutter Client';
  }

  let os = 'Unknown OS';
  if (ua.includes('windows')) {
    os = 'Windows';
  } else if (ua.includes('macintosh') || ua.includes('mac os x')) {
    os = 'macOS';
  } else if (ua.includes('iphone') || ua.includes('ipad') || ua.includes('ipod')) {
    os = 'iOS';
  } else if (ua.includes('android')) {
    os = 'Android';
  } else if (ua.includes('linux')) {
    os = 'Linux';
  }

  return { device, browser, os };
}

module.exports = { parseUserAgent };
