String getServicePersonIconPath(String serviceType) {
  switch (serviceType) {
    case 'Ambulance':
      return 'assets/icons/p1.png';
    case 'Fire':
      return 'assets/icons/p2.png';
    case 'Police':
      return 'assets/icons/p3.png'; // Assuming p3 for police
    default:
      return 'assets/p1.png'; // Fallback
  }
}
