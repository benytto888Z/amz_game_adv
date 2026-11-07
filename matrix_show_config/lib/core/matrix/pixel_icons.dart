/// Original 5x5 icons. IDs and row bytes must match iconesPub in the firmware.
/// Each row uses five low bits, bit 4 on the left. Zero means no icon.
const List<List<int>> pixelIcons = <List<int>>[
  <int>[0, 0, 0, 0, 0],
  <int>[10, 31, 31, 14, 4], // heart
  <int>[14, 21, 17, 21, 14], // face
  <int>[4, 21, 14, 31, 10], // star
];
