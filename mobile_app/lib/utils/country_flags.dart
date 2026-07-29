/// Maps Jolpica's `country` strings (as used in Circuit.Location) to a flag
/// emoji. Not exhaustive - anything unmapped falls back to a checkered flag
/// rather than breaking the layout.
const Map<String, String> _countryFlags = {
  'Australia': '🇦🇺',
  'China': '🇨🇳',
  'Japan': '🇯🇵',
  'USA': '🇺🇸',
  'United States': '🇺🇸',
  'Canada': '🇨🇦',
  'Monaco': '🇲🇨',
  'Spain': '🇪🇸',
  'Austria': '🇦🇹',
  'UK': '🇬🇧',
  'United Kingdom': '🇬🇧',
  'Great Britain': '🇬🇧',
  'Belgium': '🇧🇪',
  'Hungary': '🇭🇺',
  'Netherlands': '🇳🇱',
  'Italy': '🇮🇹',
  'Azerbaijan': '🇦🇿',
  'Singapore': '🇸🇬',
  'Mexico': '🇲🇽',
  'Brazil': '🇧🇷',
  'Qatar': '🇶🇦',
  'UAE': '🇦🇪',
  'United Arab Emirates': '🇦🇪',
  'Bahrain': '🇧🇭',
  'Saudi Arabia': '🇸🇦',
  'France': '🇫🇷',
  'Germany': '🇩🇪',
  'Portugal': '🇵🇹',
  'Russia': '🇷🇺',
  'Turkey': '🇹🇷',
  'South Korea': '🇰🇷',
  'India': '🇮🇳',
  'Malaysia': '🇲🇾',
  'Vietnam': '🇻🇳',
  'Sweden': '🇸🇪',
  'South Africa': '🇿🇦',
  'Argentina': '🇦🇷',
  'Switzerland': '🇨🇭',
  'Morocco': '🇲🇦',
};

String countryFlag(String? country) {
  if (country == null) return '🏁';
  return _countryFlags[country] ?? '🏁';
}
