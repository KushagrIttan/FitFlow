enum BodyZone {
  upper,
  lower,
  footwear,
  accessory,
}

enum ItemCategory {
  cap(BodyZone.accessory),
  sunglasses(BodyZone.accessory),
  glasses(BodyZone.accessory),
  shirt(BodyZone.upper),
  tee(BodyZone.upper),
  jacket(BodyZone.upper),
  hoodie(BodyZone.upper),
  sweater(BodyZone.upper),
  otherUpper(BodyZone.upper),
  jeans(BodyZone.lower),
  trousers(BodyZone.lower),
  shorts(BodyZone.lower),
  otherLower(BodyZone.lower),
  shoes(BodyZone.footwear),
  otherFootwear(BodyZone.footwear),
  accessory(BodyZone.accessory);

  final BodyZone zone;
  const ItemCategory(this.zone);
}

enum Fit {
  slim,
  regular,
  oversized,
}
