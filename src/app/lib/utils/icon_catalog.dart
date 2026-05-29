import 'package:flutter/material.dart';

/// One selectable icon plus lowercase [keywords] used for search.
class IconEntry {
  const IconEntry(this.icon, this.keywords);
  final IconData icon;
  final String keywords;
}

/// A named group of icons shown as a section in the picker.
class IconCategory {
  const IconCategory(this.name, this.entries);
  final String name;
  final List<IconEntry> entries;
}

/// Curated Material icons grouped for the picker. Each is a `const IconData`, so
/// they stay tree-shakeable; only the chosen code point is stored on the model.
const List<IconCategory> iconCatalog = [
  IconCategory('Activity', [
    IconEntry(Icons.directions_run, 'run running jog'),
    IconEntry(Icons.directions_walk, 'walk walking steps'),
    IconEntry(Icons.fitness_center, 'gym weights workout fitness'),
    IconEntry(Icons.self_improvement, 'meditate yoga mindful calm'),
    IconEntry(Icons.sports_gymnastics, 'stretch gymnastics exercise'),
    IconEntry(Icons.pedal_bike, 'bike cycling bicycle'),
    IconEntry(Icons.pool, 'swim swimming pool'),
    IconEntry(Icons.hiking, 'hike hiking trek mountain'),
    IconEntry(Icons.sports_basketball, 'basketball ball'),
    IconEntry(Icons.sports_soccer, 'soccer football ball'),
    IconEntry(Icons.sports_tennis, 'tennis racket'),
    IconEntry(Icons.sports_esports, 'game gaming controller'),
  ]),
  IconCategory('Health', [
    IconEntry(Icons.favorite, 'heart love health'),
    IconEntry(Icons.monitor_heart, 'heart rate health pulse'),
    IconEntry(Icons.water_drop, 'water hydrate drink'),
    IconEntry(Icons.local_drink, 'drink water glass'),
    IconEntry(Icons.medication, 'medicine pills meds'),
    IconEntry(Icons.healing, 'heal bandage recovery'),
    IconEntry(Icons.spa, 'spa relax wellness'),
    IconEntry(Icons.bedtime, 'sleep night bed moon'),
    IconEntry(Icons.restaurant, 'eat food meal'),
    IconEntry(Icons.no_drinks, 'no alcohol sober'),
    IconEntry(Icons.smoke_free, 'no smoking quit'),
    IconEntry(Icons.psychology, 'mind brain therapy'),
  ]),
  IconCategory('Study & Work', [
    IconEntry(Icons.menu_book, 'read book study reading'),
    IconEntry(Icons.school, 'school study learn class'),
    IconEntry(Icons.edit_note, 'notes write journal'),
    IconEntry(Icons.code, 'code coding program dev'),
    IconEntry(Icons.work, 'work job office briefcase'),
    IconEntry(Icons.laptop_mac, 'laptop computer work'),
    IconEntry(Icons.science, 'science lab experiment'),
    IconEntry(Icons.calculate, 'math calculate numbers'),
    IconEntry(Icons.translate, 'language translate learn'),
    IconEntry(Icons.lightbulb, 'idea light think'),
    IconEntry(Icons.business_center, 'business work case'),
    IconEntry(Icons.draw, 'draw write pen'),
  ]),
  IconCategory('Creative', [
    IconEntry(Icons.brush, 'paint art brush'),
    IconEntry(Icons.palette, 'art paint color palette'),
    IconEntry(Icons.music_note, 'music song note'),
    IconEntry(Icons.headphones, 'music headphones listen'),
    IconEntry(Icons.piano, 'piano music keys'),
    IconEntry(Icons.mic, 'sing mic voice record'),
    IconEntry(Icons.camera_alt, 'camera photo'),
    IconEntry(Icons.movie, 'movie film video'),
    IconEntry(Icons.theater_comedy, 'theater drama acting'),
    IconEntry(Icons.photo_camera, 'photo camera picture'),
    IconEntry(Icons.auto_stories, 'story book writing'),
    IconEntry(Icons.color_lens, 'color art paint'),
  ]),
  IconCategory('Lifestyle', [
    IconEntry(Icons.coffee, 'coffee cafe drink'),
    IconEntry(Icons.local_cafe, 'cafe coffee tea'),
    IconEntry(Icons.savings, 'save money savings piggy'),
    IconEntry(Icons.cleaning_services, 'clean cleaning chores'),
    IconEntry(Icons.shopping_cart, 'shop shopping buy cart'),
    IconEntry(Icons.pets, 'pet dog cat animal'),
    IconEntry(Icons.local_florist, 'flower plant garden'),
    IconEntry(Icons.eco, 'eco nature leaf green'),
    IconEntry(Icons.wb_sunny, 'sun sunny day weather'),
    IconEntry(Icons.nightlight, 'night moon sleep'),
    IconEntry(Icons.home, 'home house'),
    IconEntry(Icons.checkroom, 'clothes wardrobe closet'),
  ]),
  IconCategory('Food & Drink', [
    IconEntry(Icons.restaurant_menu, 'menu food restaurant'),
    IconEntry(Icons.lunch_dining, 'lunch burger food'),
    IconEntry(Icons.local_pizza, 'pizza food'),
    IconEntry(Icons.ramen_dining, 'ramen noodles food'),
    IconEntry(Icons.icecream, 'icecream dessert sweet'),
    IconEntry(Icons.cake, 'cake dessert birthday'),
    IconEntry(Icons.egg, 'egg breakfast food'),
    IconEntry(Icons.set_meal, 'meal food dinner'),
    IconEntry(Icons.local_bar, 'drink bar cocktail alcohol'),
    IconEntry(Icons.emoji_food_beverage, 'tea drink hot'),
    IconEntry(Icons.bakery_dining, 'bread bakery croissant'),
    IconEntry(Icons.local_dining, 'food dining eat'),
  ]),
];
