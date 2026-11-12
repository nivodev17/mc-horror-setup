// Zombie wasteland rules: starter kit, guns and car parts in loot, ammo from zombies.
// Installed to kubejs/server_scripts/wasteland.js by the pack installer.

function wlGun(id, mode, rounds, chambered) {
  var nbt = '{GunId:"tacz:' + id + '",GunFireMode:"' + mode + '",GunCurrentAmmoCount:' + rounds
  if (chambered) nbt += ',HasBulletInBarrel:1b'
  return Item.of('tacz:modern_kinetic_gun', nbt + '}')
}

function wlAmmo(id, count) {
  return Item.of('tacz:ammo', count, '{AmmoId:"tacz:' + id + '"}')
}

function wlPart(id) {
  return Item.of('tacz:attachment', '{AttachmentId:"tacz:' + id + '"}')
}

PlayerEvents.loggedIn(function (event) {
  var player = event.player
  if (player.stages.has('wasteland_starter_kit')) return
  player.stages.add('wasteland_starter_kit')

  player.give(wlGun('glock_17', 'SEMI', 17, true))
  player.give(wlAmmo('9mm', 30))
  player.give(wlAmmo('9mm', 30))
  player.give(wlGun('db_short', 'SEMI', 2, false))
  player.give(wlAmmo('12g', 16))
  player.give(Item.of('minecraft:iron_axe'))
  player.give(Item.of('minecraft:bread', 12))
  player.give(Item.of('minecraft:torch', 16))
  player.give(Item.of('car:car_workshop', 1))
  player.give(Item.of('car:car_workshop_outter', 8))
  player.tell('You wake up in the ruins. Search buildings for guns, ammo and car parts.')
})

LootJS.modifiers(function (event) {
  // Ammo: common in every chest
  event.addLootTypeModifier(LootType.CHEST).randomChance(0.45).addWeightedLoot([1, 2], [
    wlAmmo('9mm', 20).withChance(30),
    wlAmmo('45acp', 14).withChance(18),
    wlAmmo('12g', 8).withChance(20),
    wlAmmo('556x45', 20).withChance(14),
    wlAmmo('762x39', 20).withChance(14),
    wlAmmo('30_06', 8).withChance(6),
    wlAmmo('792x57', 8).withChance(5),
    wlAmmo('50ae', 7).withChance(4),
    wlAmmo('57x28', 25).withChance(3),
    wlAmmo('762x54', 10).withChance(3),
    wlAmmo('338', 5).withChance(2)
  ])

  // Common guns: pistols, shotguns, old rifles
  event.addLootTypeModifier(LootType.CHEST).randomChance(0.10).addWeightedLoot([
    wlGun('glock_17', 'SEMI', 17, true).withChance(22),
    wlGun('m1911', 'SEMI', 7, true).withChance(20),
    wlGun('db_short', 'SEMI', 2, false).withChance(16),
    wlGun('m870', 'SEMI', 5, false).withChance(14),
    wlGun('uzi', 'AUTO', 20, false).withChance(10),
    wlGun('sks_tactical', 'SEMI', 10, true).withChance(10),
    wlGun('kar98', 'SEMI', 4, false).withChance(8)
  ])

  // Rare guns: rifles and SMGs
  event.addLootTypeModifier(LootType.CHEST).randomChance(0.035).addWeightedLoot([
    wlGun('ak47', 'AUTO', 30, true).withChance(16),
    wlGun('m4a1', 'AUTO', 30, true).withChance(14),
    wlGun('m16a1', 'AUTO', 20, true).withChance(10),
    wlGun('hk_mp5a5', 'AUTO', 30, true).withChance(12),
    wlGun('ump45', 'AUTO', 25, true).withChance(10),
    wlGun('scar_l', 'AUTO', 30, true).withChance(8),
    wlGun('m1014', 'SEMI', 6, true).withChance(8),
    wlGun('m700', 'SEMI', 5, false).withChance(8),
    wlGun('deagle', 'SEMI', 7, true).withChance(6),
    wlGun('vector45', 'AUTO', 20, true).withChance(4),
    wlGun('p90', 'AUTO', 50, true).withChance(2),
    wlGun('svd', 'SEMI', 10, true).withChance(2)
  ])

  // Jackpot guns
  event.addLootTypeModifier(LootType.CHEST).randomChance(0.008).addWeightedLoot([
    wlGun('ai_awp', 'SEMI', 5, false).withChance(5),
    wlGun('m249', 'AUTO', 75, false).withChance(4),
    wlGun('rpg7', 'SEMI', 1, false).withChance(1)
  ])

  // Attachments
  event.addLootTypeModifier(LootType.CHEST).randomChance(0.06).addWeightedLoot([
    wlPart('sight_t1').withChance(10),
    wlPart('sight_exp3').withChance(8),
    wlPart('scope_acog_ta31').withChance(6),
    wlPart('scope_standard_8x').withChance(3),
    wlPart('muzzle_silencer_phantom_s1').withChance(6),
    wlPart('grip_vertical_talon').withChance(8),
    wlPart('extended_mag_1').withChance(8),
    wlPart('laser_compact').withChance(6)
  ])

  // Food and supplies
  event.addLootTypeModifier(LootType.CHEST).randomChance(0.35).addWeightedLoot([1, 2], [
    Item.of('minecraft:bread', 3).withChance(20),
    Item.of('minecraft:cooked_beef', 2).withChance(12),
    Item.of('minecraft:baked_potato', 3).withChance(12),
    Item.of('minecraft:torch', 6).withChance(12),
    Item.of('minecraft:iron_ingot', 3).withChance(10),
    Item.of('minecraft:gunpowder', 4).withChance(8),
    Item.of('minecraft:golden_apple').withChance(2)
  ])

  // Car parts and fuel
  event.addLootTypeModifier(LootType.CHEST).randomChance(0.08).addWeightedLoot([
    Item.of('car:wheel', 2).withChance(22),
    Item.of('car:bio_diesel_bucket').withChance(16),
    Item.of('car:canister').withChance(10),
    Item.of('car:engine_3_cylinder').withChance(10),
    Item.of('car:small_tank').withChance(8),
    Item.of('car:battery').withChance(8),
    Item.of('car:repair_kit').withChance(8),
    Item.of('car:red_suv_body').withChance(5),
    Item.of('car:white_transporter_body').withChance(5),
    Item.of('car:black_sport_body').withChance(3),
    Item.of('car:engine_6_cylinder').withChance(3)
  ])

  // Zombies sometimes carry ammo
  event.addEntityLootModifier('minecraft:zombie').randomChance(0.12).addWeightedLoot([
    wlAmmo('9mm', 8).withChance(40),
    wlAmmo('12g', 4).withChance(25),
    wlAmmo('45acp', 6).withChance(20),
    wlAmmo('556x45', 8).withChance(8),
    wlAmmo('762x39', 8).withChance(7)
  ])
})
