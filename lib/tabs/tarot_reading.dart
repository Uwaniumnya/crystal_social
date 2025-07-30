import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../rewards/rewards_manager.dart';

class TarotDeck {
  final int id;
  final String name;
  final String icon;
  final String cardBackImagePath;
  final String cardFrontImagePath;
  final List<String> cardMeanings;
  final bool isOwned;

  TarotDeck({
    required this.id,
    required this.name,
    required this.icon,
    required this.cardBackImagePath,
    required this.cardFrontImagePath,
    required this.cardMeanings,
    this.isOwned = false,
  });

  TarotDeck copyWith({bool? isOwned}) {
    return TarotDeck(
      id: id,
      name: name,
      icon: icon,
      cardBackImagePath: cardBackImagePath,
      cardFrontImagePath: cardFrontImagePath,
      cardMeanings: cardMeanings,
      isOwned: isOwned ?? this.isOwned,
    );
  }
}

class TarotReadingTab extends StatefulWidget {
  final String userId;
  final SupabaseClient supabase;

  const TarotReadingTab({
    super.key,
    required this.userId,
    required this.supabase,
  });

  @override
  _TarotReadingTabState createState() => _TarotReadingTabState();
}

class _TarotReadingTabState extends State<TarotReadingTab>
    with TickerProviderStateMixin {
  late List<String> symbols;
  late List<TarotDeck> availableDecks;
  late List<TarotDeck> ownedDecks;
  late TarotDeck selectedDeck;
  late String question;
  late int selectedSymbolsCount;
  late List<String> selectedSymbols;
  late List<String> drawnCards;
  late List<String> drawnCardMeanings;
  late bool isShuffling;
  late RewardsManager _rewardsManager;
  bool _isLoadingInventory = false;

  late AnimationController symbolFadeController;
  late AnimationController cardFlipController;
  late AnimationController responseFadeController;

  late DateTime lastSessionTime;
  bool isCooldownActive = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController questionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rewardsManager = RewardsManager(widget.supabase);

    // Initialize all available tarot decks
    availableDecks = _initializeTarotDecks();
    
    // Initialize with default values
    ownedDecks = [];
    selectedDeck = availableDecks[0].copyWith(isOwned: true); // Default deck is always owned
    selectedSymbolsCount = 0;
    selectedSymbols = [];
    drawnCards = [];
    drawnCardMeanings = [];
    isShuffling = false;

    symbolFadeController = AnimationController(vsync: this, duration: Duration(seconds: 2));
    cardFlipController = AnimationController(vsync: this, duration: Duration(seconds: 2));
    responseFadeController = AnimationController(vsync: this, duration: Duration(seconds: 3));

    _loadUserTarotDecks();
    checkCooldown();
    loadData();
  }

  List<TarotDeck> _initializeTarotDecks() {
    return [
      TarotDeck(
        id: 1,
        name: 'Classic Rider-Waite',
        icon: 'assets/icons/tarot/deck1_icon.png',
        cardBackImagePath: 'assets/tarot/deck1/backs/tarot_back1.png',
        cardFrontImagePath: 'assets/tarot/deck1/fronts/tarot_front1.png',
        cardMeanings: [
          // Major Arcana (0-21)
          "The Fool: New beginnings, innocence, spontaneity, taking a leap of faith",
          "The Magician: Manifestation, resourcefulness, power, having the tools you need",
          "The High Priestess: Intuition, sacred knowledge, divine feminine, inner wisdom",
          "The Empress: Nurturing, abundance, nature's bounty, creativity, fertility",
          "The Emperor: Authority, structure, stability, leadership, control",
          "The Hierophant: Tradition, conformity, morality, ethics, spiritual guidance",
          "The Lovers: Union, partnerships, choices, love, harmony",
          "The Chariot: Willpower, determination, triumph, control, success",
          "Strength: Inner strength, courage, compassion, gentle control",
          "The Hermit: Soul searching, introspection, guidance, inner wisdom",
          "Wheel of Fortune: Change, cycles, fate, luck, karma",
          "Justice: Fairness, truth, cause and effect, law, balance",
          "The Hanged Man: Suspension, letting go, surrender, new perspective",
          "Death: Transformation, endings, rebirth, major change",
          "Temperance: Balance, moderation, patience, harmony, healing",
          "The Devil: Bondage, materialism, ignorance, temptation, addiction",
          "The Tower: Sudden change, upheaval, revelation, destruction, awakening",
          "The Star: Hope, faith, purpose, renewal, spirituality",
          "The Moon: Illusion, fear, anxiety, subconscious, dreams",
          "The Sun: Joy, success, vitality, positivity, achievement",
          "Judgement: Rebirth, inner calling, absolution, reflection",
          "The World: Completion, accomplishment, travel, fulfillment",
          
          // Cups (22-35)
          "Ace of Cups: New love, emotional fulfillment, spiritual awakening",
          "Two of Cups: Partnership, unity, mutual attraction, love",
          "Three of Cups: Friendship, celebration, community, creativity",
          "Four of Cups: Apathy, contemplation, disconnectedness, reevaluation",
          "Five of Cups: Loss, regret, disappointment, grief, mourning",
          "Six of Cups: Nostalgia, childhood memories, innocence, reunion",
          "Seven of Cups: Illusion, choices, wishful thinking, imagination",
          "Eight of Cups: Abandonment, withdrawal, escapism, seeking truth",
          "Nine of Cups: Satisfaction, contentment, gratitude, wish fulfillment",
          "Ten of Cups: Happiness, harmony, emotional fulfillment, family",
          "Page of Cups: Creative opportunities, intuitive messages, curiosity",
          "Knight of Cups: Romance, charm, imagination, following your heart",
          "Queen of Cups: Emotional security, intuitive, compassionate, calm",
          "King of Cups: Emotional balance, generosity, diplomatic, devoted",
          
          // Pentacles (36-49)
          "Ace of Pentacles: New opportunities, manifestation, prosperity, new venture",
          "Two of Pentacles: Multiple priorities, time management, adaptability",
          "Three of Pentacles: Collaboration, teamwork, skill building, learning",
          "Four of Pentacles: Conservation, frugality, security, control",
          "Five of Pentacles: Financial loss, poverty, insecurity, isolation",
          "Six of Pentacles: Generosity, charity, giving and receiving, gratitude",
          "Seven of Pentacles: Assessment, hard work, perseverance, investment",
          "Eight of Pentacles: Skill development, quality, craftsmanship, expertise",
          "Nine of Pentacles: Abundance, luxury, self-reliance, financial independence",
          "Ten of Pentacles: Wealth, financial security, family, long-term success",
          "Page of Pentacles: Manifestation, financial opportunity, skill development",
          "Knight of Pentacles: Hard work, productivity, routine, conservatism",
          "Queen of Pentacles: Nurturing, practical, providing, down-to-earth",
          "King of Pentacles: Financial success, leadership, security, generosity",
          
          // Swords (50-63)
          "Ace of Swords: New ideas, mental clarity, breakthrough, communication",
          "Two of Swords: Difficult decisions, weighing options, indecision",
          "Three of Swords: Heartbreak, sorrow, grief, betrayal, separation",
          "Four of Swords: Rest, contemplation, recovery, passive preparation",
          "Five of Swords: Conflict, tension, loss, defeat, win at all costs",
          "Six of Swords: Transition, change, rite of passage, moving forward",
          "Seven of Swords: Deception, theft, getting away with something, stealth",
          "Eight of Swords: Imprisonment, entrapment, self-imposed restriction",
          "Nine of Swords: Anxiety, worry, fear, depression, nightmares",
          "Ten of Swords: Painful endings, deep wounds, betrayal, crisis",
          "Page of Swords: New ideas, curiosity, restlessness, communication",
          "Knight of Swords: Ambitious, action-oriented, driven, impulsive",
          "Queen of Swords: Independent, unbiased judgment, clear boundaries",
          "King of Swords: Mental clarity, intellectual power, authority, truth",
          
          // Wands (64-77)
          "Ace of Wands: Inspiration, new opportunities, growth, potential",
          "Two of Wands: Future planning, making decisions, leaving comfort zone",
          "Three of Wands: Preparation, foresight, enterprise, expansion",
          "Four of Wands: Celebration, harmony, home, marriage, community",
          "Five of Wands: Conflict, competition, tension, diversity",
          "Six of Wands: Success, public recognition, progress, self-confidence",
          "Seven of Wands: Challenge, competition, protection, perseverance",
          "Eight of Wands: Movement, speed, progress, quick decisions",
          "Nine of Wands: Resilience, courage, persistence, test of faith",
          "Ten of Wands: Burden, extra responsibility, hard work, completion",
          "Page of Wands: Exploration, excitement, freedom, new ideas",
          "Knight of Wands: Energy, passion, impulsive, adventure-seeking",
          "Queen of Wands: Courage, confidence, independence, social butterfly",
          "King of Wands: Leadership, vision, entrepreneur, honour"
        ],
        isOwned: true, // Default deck always owned
      ),
      TarotDeck(
        id: 2,
        name: 'Water-Colored Deck',
        icon: 'assets/icons/tarot/deck2_icon.png',
        cardBackImagePath: 'assets/tarot/deck2/backs/tarot_back1.png',
        cardFrontImagePath: 'assets/tarot/deck2/fronts/tarot_front1.png',
        cardMeanings: [
          // Major Arcana only (22 cards)
          "The Fool: New beginnings, innocence, spontaneity, taking a leap of faith",
          "The Magician: Manifestation, resourcefulness, power, having the tools you need",
          "The High Priestess: Intuition, sacred knowledge, divine feminine, inner wisdom",
          "The Empress: Nurturing, abundance, nature's bounty, creativity, fertility",
          "The Emperor: Authority, structure, stability, leadership, control",
          "The Hierophant: Tradition, conformity, morality, ethics, spiritual guidance",
          "The Lovers: Union, partnerships, choices, love, harmony",
          "The Chariot: Willpower, determination, triumph, control, success",
          "Strength: Inner strength, courage, compassion, gentle control",
          "The Hermit: Soul searching, introspection, guidance, inner wisdom",
          "Wheel of Fortune: Change, cycles, fate, luck, karma",
          "Justice: Fairness, truth, cause and effect, law, balance",
          "The Hanged Man: Suspension, letting go, surrender, new perspective",
          "Death: Transformation, endings, rebirth, major change",
          "Temperance: Balance, moderation, patience, harmony, healing",
          "The Devil: Bondage, materialism, ignorance, temptation, addiction",
          "The Tower: Sudden change, upheaval, revelation, destruction, awakening",
          "The Star: Hope, faith, purpose, renewal, spirituality",
          "The Moon: Illusion, fear, anxiety, subconscious, dreams",
          "The Sun: Joy, success, vitality, positivity, achievement",
          "Judgement: Rebirth, inner calling, absolution, reflection",
          "The World: Completion, accomplishment, travel, fulfillment",
        ],
        isOwned: false, // Must be purchased from shop
      ),
      TarotDeck(
        id: 3,
        name: 'Gilded Deck',
        icon: 'assets/icons/tarot/deck3_icon.png',
        cardBackImagePath: 'assets/tarot/deck3/backs/tarot_back1.png',
        cardFrontImagePath: 'assets/tarot/deck3/fronts/tarot_front1.png',
        cardMeanings: [
          // Major Arcana only (22 cards)
          "The Fool: New beginnings, innocence, spontaneity, taking a leap of faith",
          "The Magician: Manifestation, resourcefulness, power, having the tools you need",
          "The High Priestess: Intuition, sacred knowledge, divine feminine, inner wisdom",
          "The Empress: Nurturing, abundance, nature's bounty, creativity, fertility",
          "The Emperor: Authority, structure, stability, leadership, control",
          "The Hierophant: Tradition, conformity, morality, ethics, spiritual guidance",
          "The Lovers: Union, partnerships, choices, love, harmony",
          "The Chariot: Willpower, determination, triumph, control, success",
          "Strength: Inner strength, courage, compassion, gentle control",
          "The Hermit: Soul searching, introspection, guidance, inner wisdom",
          "Wheel of Fortune: Change, cycles, fate, luck, karma",
          "Justice: Fairness, truth, cause and effect, law, balance",
          "The Hanged Man: Suspension, letting go, surrender, new perspective",
          "Death: Transformation, endings, rebirth, major change",
          "Temperance: Balance, moderation, patience, harmony, healing",
          "The Devil: Bondage, materialism, ignorance, temptation, addiction",
          "The Tower: Sudden change, upheaval, revelation, destruction, awakening",
          "The Star: Hope, faith, purpose, renewal, spirituality",
          "The Moon: Illusion, fear, anxiety, subconscious, dreams",
          "The Sun: Joy, success, vitality, positivity, achievement",
          "Judgement: Rebirth, inner calling, absolution, reflection",
          "The World: Completion, accomplishment, travel, fulfillment",
        ],
        isOwned: false, // Must be purchased from shop
      ),
      TarotDeck(
        id: 4,
        name: 'Merlin Deck',
        icon: 'assets/icons/tarot/deck4_icon.png',
        cardBackImagePath: 'assets/tarot/deck4/backs/tarot_back1.png',
        cardFrontImagePath: 'assets/tarot/deck4/fronts/tarot_front1.png',
        cardMeanings: [
          // Major Arcana (0-21)
          "The Fool: New beginnings, innocence, spontaneity, taking a leap of faith",
          "The Magician: Manifestation, resourcefulness, power, having the tools you need",
          "The High Priestess: Intuition, sacred knowledge, divine feminine, inner wisdom",
          "The Empress: Nurturing, abundance, nature's bounty, creativity, fertility",
          "The Emperor: Authority, structure, stability, leadership, control",
          "The Hierophant: Tradition, conformity, morality, ethics, spiritual guidance",
          "The Lovers: Union, partnerships, choices, love, harmony",
          "The Chariot: Willpower, determination, triumph, control, success",
          "Strength: Inner strength, courage, compassion, gentle control",
          "The Hermit: Soul searching, introspection, guidance, inner wisdom",
          "Wheel of Fortune: Change, cycles, fate, luck, karma",
          "Justice: Fairness, truth, cause and effect, law, balance",
          "The Hanged Man: Suspension, letting go, surrender, new perspective",
          "Death: Transformation, endings, rebirth, major change",
          "Temperance: Balance, moderation, patience, harmony, healing",
          "The Devil: Bondage, materialism, ignorance, temptation, addiction",
          "The Tower: Sudden change, upheaval, revelation, destruction, awakening",
          "The Star: Hope, faith, purpose, renewal, spirituality",
          "The Moon: Illusion, fear, anxiety, subconscious, dreams",
          "The Sun: Joy, success, vitality, positivity, achievement",
          "Judgement: Rebirth, inner calling, absolution, reflection",
          "The World: Completion, accomplishment, travel, fulfillment",
          
          // Cups (22-35)
          "Ace of Cups: New love, emotional fulfillment, spiritual awakening",
          "Two of Cups: Partnership, unity, mutual attraction, love",
          "Three of Cups: Friendship, celebration, community, creativity",
          "Four of Cups: Apathy, contemplation, disconnectedness, reevaluation",
          "Five of Cups: Loss, regret, disappointment, grief, mourning",
          "Six of Cups: Nostalgia, childhood memories, innocence, reunion",
          "Seven of Cups: Illusion, choices, wishful thinking, imagination",
          "Eight of Cups: Abandonment, withdrawal, escapism, seeking truth",
          "Nine of Cups: Satisfaction, contentment, gratitude, wish fulfillment",
          "Ten of Cups: Happiness, harmony, emotional fulfillment, family",
          "Page of Cups: Creative opportunities, intuitive messages, curiosity",
          "Knight of Cups: Romance, charm, imagination, following your heart",
          "Queen of Cups: Emotional security, intuitive, compassionate, calm",
          "King of Cups: Emotional balance, generosity, diplomatic, devoted",
          
          // Pentacles (36-49)
          "Ace of Pentacles: New opportunities, manifestation, prosperity, new venture",
          "Two of Pentacles: Multiple priorities, time management, adaptability",
          "Three of Pentacles: Collaboration, teamwork, skill building, learning",
          "Four of Pentacles: Conservation, frugality, security, control",
          "Five of Pentacles: Financial loss, poverty, insecurity, isolation",
          "Six of Pentacles: Generosity, charity, giving and receiving, gratitude",
          "Seven of Pentacles: Assessment, hard work, perseverance, investment",
          "Eight of Pentacles: Skill development, quality, craftsmanship, expertise",
          "Nine of Pentacles: Abundance, luxury, self-reliance, financial independence",
          "Ten of Pentacles: Wealth, financial security, family, long-term success",
          "Page of Pentacles: Manifestation, financial opportunity, skill development",
          "Knight of Pentacles: Hard work, productivity, routine, conservatism",
          "Queen of Pentacles: Nurturing, practical, providing, down-to-earth",
          "King of Pentacles: Financial success, leadership, security, generosity",
          
          // Swords (50-63)
          "Ace of Swords: New ideas, mental clarity, breakthrough, communication",
          "Two of Swords: Difficult decisions, weighing options, indecision",
          "Three of Swords: Heartbreak, sorrow, grief, betrayal, separation",
          "Four of Swords: Rest, contemplation, recovery, passive preparation",
          "Five of Swords: Conflict, tension, loss, defeat, win at all costs",
          "Six of Swords: Transition, change, rite of passage, moving forward",
          "Seven of Swords: Deception, theft, getting away with something, stealth",
          "Eight of Swords: Imprisonment, entrapment, self-imposed restriction",
          "Nine of Swords: Anxiety, worry, fear, depression, nightmares",
          "Ten of Swords: Painful endings, deep wounds, betrayal, crisis",
          "Page of Swords: New ideas, curiosity, restlessness, communication",
          "Knight of Swords: Ambitious, action-oriented, driven, impulsive",
          "Queen of Swords: Independent, unbiased judgment, clear boundaries",
          "King of Swords: Mental clarity, intellectual power, authority, truth",
          
          // Wands (64-77)
          "Ace of Wands: Inspiration, new opportunities, growth, potential",
          "Two of Wands: Future planning, making decisions, leaving comfort zone",
          "Three of Wands: Preparation, foresight, enterprise, expansion",
          "Four of Wands: Celebration, harmony, home, marriage, community",
          "Five of Wands: Conflict, competition, tension, diversity",
          "Six of Wands: Success, public recognition, progress, self-confidence",
          "Seven of Wands: Challenge, competition, protection, perseverance",
          "Eight of Wands: Movement, speed, progress, quick decisions",
          "Nine of Wands: Resilience, courage, persistence, test of faith",
          "Ten of Wands: Burden, extra responsibility, hard work, completion",
          "Page of Wands: Exploration, excitement, freedom, new ideas",
          "Knight of Wands: Energy, passion, impulsive, adventure-seeking",
          "Queen of Wands: Courage, confidence, independence, social butterfly",
          "King of Wands: Leadership, vision, entrepreneur, honour"
        ],
        isOwned: false, // Must be purchased from shop
      ),
      TarotDeck(
        id: 5,
        name: 'Enchanted Deck',
        icon: 'assets/icons/tarot/deck5_icon.png',
        cardBackImagePath: 'assets/tarot/deck5/backs/tarot_back1.png',
        cardFrontImagePath: 'assets/tarot/deck5/fronts/tarot_front1.png',
        cardMeanings: [
          // Major Arcana (0-21)
          "The Fool: New beginnings, innocence, spontaneity, taking a leap of faith",
          "The Magician: Manifestation, resourcefulness, power, having the tools you need",
          "The High Priestess: Intuition, sacred knowledge, divine feminine, inner wisdom",
          "The Empress: Nurturing, abundance, nature's bounty, creativity, fertility",
          "The Emperor: Authority, structure, stability, leadership, control",
          "The Hierophant: Tradition, conformity, morality, ethics, spiritual guidance",
          "The Lovers: Union, partnerships, choices, love, harmony",
          "The Chariot: Willpower, determination, triumph, control, success",
          "Strength: Inner strength, courage, compassion, gentle control",
          "The Hermit: Soul searching, introspection, guidance, inner wisdom",
          "Wheel of Fortune: Change, cycles, fate, luck, karma",
          "Justice: Fairness, truth, cause and effect, law, balance",
          "The Hanged Man: Suspension, letting go, surrender, new perspective",
          "Death: Transformation, endings, rebirth, major change",
          "Temperance: Balance, moderation, patience, harmony, healing",
          "The Devil: Bondage, materialism, ignorance, temptation, addiction",
          "The Tower: Sudden change, upheaval, revelation, destruction, awakening",
          "The Star: Hope, faith, purpose, renewal, spirituality",
          "The Moon: Illusion, fear, anxiety, subconscious, dreams",
          "The Sun: Joy, success, vitality, positivity, achievement",
          "Judgement: Rebirth, inner calling, absolution, reflection",
          "The World: Completion, accomplishment, travel, fulfillment",
          
          // Cups (22-35)
          "Ace of Cups: New love, emotional fulfillment, spiritual awakening",
          "Two of Cups: Partnership, unity, mutual attraction, love",
          "Three of Cups: Friendship, celebration, community, creativity",
          "Four of Cups: Apathy, contemplation, disconnectedness, reevaluation",
          "Five of Cups: Loss, regret, disappointment, grief, mourning",
          "Six of Cups: Nostalgia, childhood memories, innocence, reunion",
          "Seven of Cups: Illusion, choices, wishful thinking, imagination",
          "Eight of Cups: Abandonment, withdrawal, escapism, seeking truth",
          "Nine of Cups: Satisfaction, contentment, gratitude, wish fulfillment",
          "Ten of Cups: Happiness, harmony, emotional fulfillment, family",
          "Page of Cups: Creative opportunities, intuitive messages, curiosity",
          "Knight of Cups: Romance, charm, imagination, following your heart",
          "Queen of Cups: Emotional security, intuitive, compassionate, calm",
          "King of Cups: Emotional balance, generosity, diplomatic, devoted",
          
          // Pentacles (36-49)
          "Ace of Pentacles: New opportunities, manifestation, prosperity, new venture",
          "Two of Pentacles: Multiple priorities, time management, adaptability",
          "Three of Pentacles: Collaboration, teamwork, skill building, learning",
          "Four of Pentacles: Conservation, frugality, security, control",
          "Five of Pentacles: Financial loss, poverty, insecurity, isolation",
          "Six of Pentacles: Generosity, charity, giving and receiving, gratitude",
          "Seven of Pentacles: Assessment, hard work, perseverance, investment",
          "Eight of Pentacles: Skill development, quality, craftsmanship, expertise",
          "Nine of Pentacles: Abundance, luxury, self-reliance, financial independence",
          "Ten of Pentacles: Wealth, financial security, family, long-term success",
          "Page of Pentacles: Manifestation, financial opportunity, skill development",
          "Knight of Pentacles: Hard work, productivity, routine, conservatism",
          "Queen of Pentacles: Nurturing, practical, providing, down-to-earth",
          "King of Pentacles: Financial success, leadership, security, generosity",
          
          // Swords (50-63)
          "Ace of Swords: New ideas, mental clarity, breakthrough, communication",
          "Two of Swords: Difficult decisions, weighing options, indecision",
          "Three of Swords: Heartbreak, sorrow, grief, betrayal, separation",
          "Four of Swords: Rest, contemplation, recovery, passive preparation",
          "Five of Swords: Conflict, tension, loss, defeat, win at all costs",
          "Six of Swords: Transition, change, rite of passage, moving forward",
          "Seven of Swords: Deception, theft, getting away with something, stealth",
          "Eight of Swords: Imprisonment, entrapment, self-imposed restriction",
          "Nine of Swords: Anxiety, worry, fear, depression, nightmares",
          "Ten of Swords: Painful endings, deep wounds, betrayal, crisis",
          "Page of Swords: New ideas, curiosity, restlessness, communication",
          "Knight of Swords: Ambitious, action-oriented, driven, impulsive",
          "Queen of Swords: Independent, unbiased judgment, clear boundaries",
          "King of Swords: Mental clarity, intellectual power, authority, truth",
          
          // Wands (64-77)
          "Ace of Wands: Inspiration, new opportunities, growth, potential",
          "Two of Wands: Future planning, making decisions, leaving comfort zone",
          "Three of Wands: Preparation, foresight, enterprise, expansion",
          "Four of Wands: Celebration, harmony, home, marriage, community",
          "Five of Wands: Conflict, competition, tension, diversity",
          "Six of Wands: Success, public recognition, progress, self-confidence",
          "Seven of Wands: Challenge, competition, protection, perseverance",
          "Eight of Wands: Movement, speed, progress, quick decisions",
          "Nine of Wands: Resilience, courage, persistence, test of faith",
          "Ten of Wands: Burden, extra responsibility, hard work, completion",
          "Page of Wands: Exploration, excitement, freedom, new ideas",
          "Knight of Wands: Energy, passion, impulsive, adventure-seeking",
          "Queen of Wands: Courage, confidence, independence, social butterfly",
          "King of Wands: Leadership, vision, entrepreneur, honour"
        ],
        isOwned: false, // Must be purchased from shop
      ),
      TarotDeck(
        id: 6,
        name: 'Forest Spirits Deck',
        icon: 'assets/icons/tarot/deck6_icon.png',
        cardBackImagePath: 'assets/tarot/deck6/backs/tarot_back1.png',
        cardFrontImagePath: 'assets/tarot/deck6/fronts/tarot_front1.png',
        cardMeanings: [
          // Major Arcana (0-21)
          "The Fool: New beginnings, innocence, spontaneity, taking a leap of faith",
          "The Magician: Manifestation, resourcefulness, power, having the tools you need",
          "The High Priestess: Intuition, sacred knowledge, divine feminine, inner wisdom",
          "The Empress: Nurturing, abundance, nature's bounty, creativity, fertility",
          "The Emperor: Authority, structure, stability, leadership, control",
          "The Hierophant: Tradition, conformity, morality, ethics, spiritual guidance",
          "The Lovers: Union, partnerships, choices, love, harmony",
          "The Chariot: Willpower, determination, triumph, control, success",
          "Strength: Inner strength, courage, compassion, gentle control",
          "The Hermit: Soul searching, introspection, guidance, inner wisdom",
          "Wheel of Fortune: Change, cycles, fate, luck, karma",
          "Justice: Fairness, truth, cause and effect, law, balance",
          "The Hanged Man: Suspension, letting go, surrender, new perspective",
          "Death: Transformation, endings, rebirth, major change",
          "Temperance: Balance, moderation, patience, harmony, healing",
          "The Devil: Bondage, materialism, ignorance, temptation, addiction",
          "The Tower: Sudden change, upheaval, revelation, destruction, awakening",
          "The Star: Hope, faith, purpose, renewal, spirituality",
          "The Moon: Illusion, fear, anxiety, subconscious, dreams",
          "The Sun: Joy, success, vitality, positivity, achievement",
          "Judgement: Rebirth, inner calling, absolution, reflection",
          "The World: Completion, accomplishment, travel, fulfillment",
          
          // Cups (22-35)
          "Ace of Cups: New love, emotional fulfillment, spiritual awakening",
          "Two of Cups: Partnership, unity, mutual attraction, love",
          "Three of Cups: Friendship, celebration, community, creativity",
          "Four of Cups: Apathy, contemplation, disconnectedness, reevaluation",
          "Five of Cups: Loss, regret, disappointment, grief, mourning",
          "Six of Cups: Nostalgia, childhood memories, innocence, reunion",
          "Seven of Cups: Illusion, choices, wishful thinking, imagination",
          "Eight of Cups: Abandonment, withdrawal, escapism, seeking truth",
          "Nine of Cups: Satisfaction, contentment, gratitude, wish fulfillment",
          "Ten of Cups: Happiness, harmony, emotional fulfillment, family",
          "Page of Cups: Creative opportunities, intuitive messages, curiosity",
          "Knight of Cups: Romance, charm, imagination, following your heart",
          "Queen of Cups: Emotional security, intuitive, compassionate, calm",
          "King of Cups: Emotional balance, generosity, diplomatic, devoted",
          
          // Pentacles (36-49)
          "Ace of Pentacles: New opportunities, manifestation, prosperity, new venture",
          "Two of Pentacles: Multiple priorities, time management, adaptability",
          "Three of Pentacles: Collaboration, teamwork, skill building, learning",
          "Four of Pentacles: Conservation, frugality, security, control",
          "Five of Pentacles: Financial loss, poverty, insecurity, isolation",
          "Six of Pentacles: Generosity, charity, giving and receiving, gratitude",
          "Seven of Pentacles: Assessment, hard work, perseverance, investment",
          "Eight of Pentacles: Skill development, quality, craftsmanship, expertise",
          "Nine of Pentacles: Abundance, luxury, self-reliance, financial independence",
          "Ten of Pentacles: Wealth, financial security, family, long-term success",
          "Page of Pentacles: Manifestation, financial opportunity, skill development",
          "Knight of Pentacles: Hard work, productivity, routine, conservatism",
          "Queen of Pentacles: Nurturing, practical, providing, down-to-earth",
          "King of Pentacles: Financial success, leadership, security, generosity",
          
          // Swords (50-63)
          "Ace of Swords: New ideas, mental clarity, breakthrough, communication",
          "Two of Swords: Difficult decisions, weighing options, indecision",
          "Three of Swords: Heartbreak, sorrow, grief, betrayal, separation",
          "Four of Swords: Rest, contemplation, recovery, passive preparation",
          "Five of Swords: Conflict, tension, loss, defeat, win at all costs",
          "Six of Swords: Transition, change, rite of passage, moving forward",
          "Seven of Swords: Deception, theft, getting away with something, stealth",
          "Eight of Swords: Imprisonment, entrapment, self-imposed restriction",
          "Nine of Swords: Anxiety, worry, fear, depression, nightmares",
          "Ten of Swords: Painful endings, deep wounds, betrayal, crisis",
          "Page of Swords: New ideas, curiosity, restlessness, communication",
          "Knight of Swords: Ambitious, action-oriented, driven, impulsive",
          "Queen of Swords: Independent, unbiased judgment, clear boundaries",
          "King of Swords: Mental clarity, intellectual power, authority, truth",
          
          // Wands (64-77)
          "Ace of Wands: Inspiration, new opportunities, growth, potential",
          "Two of Wands: Future planning, making decisions, leaving comfort zone",
          "Three of Wands: Preparation, foresight, enterprise, expansion",
          "Four of Wands: Celebration, harmony, home, marriage, community",
          "Five of Wands: Conflict, competition, tension, diversity",
          "Six of Wands: Success, public recognition, progress, self-confidence",
          "Seven of Wands: Challenge, competition, protection, perseverance",
          "Eight of Wands: Movement, speed, progress, quick decisions",
          "Nine of Wands: Resilience, courage, persistence, test of faith",
          "Ten of Wands: Burden, extra responsibility, hard work, completion",
          "Page of Wands: Exploration, excitement, freedom, new ideas",
          "Knight of Wands: Energy, passion, impulsive, adventure-seeking",
          "Queen of Wands: Courage, confidence, independence, social butterfly",
          "King of Wands: Leadership, vision, entrepreneur, honour"
        ],
        isOwned: false, // Must be purchased from shop
      ),
      TarotDeck(
        id: 7,
        name: 'Golden Bit Deck',
        icon: 'assets/icons/tarot/deck7_icon.png',
        cardBackImagePath: 'assets/tarot/deck7/backs/tarot_back1.png',
        cardFrontImagePath: 'assets/tarot/deck7/fronts/tarot_front1.png',
        cardMeanings: [
          // Major Arcana only (22 cards)
          "The Fool: New beginnings, innocence, spontaneity, taking a leap of faith",
          "The Magician: Manifestation, resourcefulness, power, having the tools you need",
          "The High Priestess: Intuition, sacred knowledge, divine feminine, inner wisdom",
          "The Empress: Nurturing, abundance, nature's bounty, creativity, fertility",
          "The Emperor: Authority, structure, stability, leadership, control",
          "The Hierophant: Tradition, conformity, morality, ethics, spiritual guidance",
          "The Lovers: Union, partnerships, choices, love, harmony",
          "The Chariot: Willpower, determination, triumph, control, success",
          "Strength: Inner strength, courage, compassion, gentle control",
          "The Hermit: Soul searching, introspection, guidance, inner wisdom",
          "Wheel of Fortune: Change, cycles, fate, luck, karma",
          "Justice: Fairness, truth, cause and effect, law, balance",
          "The Hanged Man: Suspension, letting go, surrender, new perspective",
          "Death: Transformation, endings, rebirth, major change",
          "Temperance: Balance, moderation, patience, harmony, healing",
          "The Devil: Bondage, materialism, ignorance, temptation, addiction",
          "The Tower: Sudden change, upheaval, revelation, destruction, awakening",
          "The Star: Hope, faith, purpose, renewal, spirituality",
          "The Moon: Illusion, fear, anxiety, subconscious, dreams",
          "The Sun: Joy, success, vitality, positivity, achievement",
          "Judgement: Rebirth, inner calling, absolution, reflection",
          "The World: Completion, accomplishment, travel, fulfillment",
        ],
        isOwned: false, // Must be purchased from shop
      ),
    ];
  }

  // Load user's owned tarot decks from inventory
  Future<void> _loadUserTarotDecks() async {
    setState(() {
      _isLoadingInventory = true;
    });

    try {
      final inventory = await _rewardsManager.getUserInventory(widget.userId);
      
      // Filter for tarot deck items (assuming category_id 6 is tarot decks)
      final tarotDeckItems = inventory.where((item) => 
        item['type'] == 'tarot_deck' || 
        item['name']?.toString().toLowerCase().contains('deck') == true ||
        item['category_reference_id'] == 6 // Tarot deck booster packs
      ).toList();

      // Update ownership status for available decks
      List<TarotDeck> updatedDecks = [];
      for (var deck in availableDecks) {
        bool isOwned = deck.id == 1 || // Default deck always owned
            tarotDeckItems.any((item) => 
              item['name']?.toString().toLowerCase() == deck.name.toLowerCase() ||
              item['id'] == deck.id ||
              (deck.name == 'Water-Colored Deck' && 
               (item['name']?.toString().toLowerCase().contains('water') == true ||
                item['name']?.toString().toLowerCase().contains('cosmic') == true ||
                item['name']?.toString().toLowerCase().contains('asteria') == true)) ||
              (deck.name == 'Gilded Deck' && 
               (item['name']?.toString().toLowerCase().contains('gilded') == true ||
                item['name']?.toString().toLowerCase().contains('mystic') == true ||
                item['name']?.toString().toLowerCase().contains('moon') == true)) ||
              (deck.name == 'Merlin Deck' && 
               (item['name']?.toString().toLowerCase().contains('merlin') == true ||
                item['name']?.toString().toLowerCase().contains('wizard') == true ||
                item['name']?.toString().toLowerCase().contains('magic') == true)) ||
              (deck.name == 'Enchanted Deck' && 
               (item['name']?.toString().toLowerCase().contains('enchanted') == true ||
                item['name']?.toString().toLowerCase().contains('fairy') == true ||
                item['name']?.toString().toLowerCase().contains('mystical') == true)) ||
              (deck.name == 'Forest Spirits Deck' && 
               (item['name']?.toString().toLowerCase().contains('forest') == true ||
                item['name']?.toString().toLowerCase().contains('spirit') == true ||
                item['name']?.toString().toLowerCase().contains('nature') == true)) ||
              (deck.name == 'Golden Bit Deck' && 
               (item['name']?.toString().toLowerCase().contains('golden') == true ||
                item['name']?.toString().toLowerCase().contains('bit') == true ||
                item['name']?.toString().toLowerCase().contains('digital') == true))
            );
        updatedDecks.add(deck.copyWith(isOwned: isOwned));
      }

      setState(() {
        availableDecks = updatedDecks;
        ownedDecks = availableDecks.where((deck) => deck.isOwned).toList();
        if (ownedDecks.isNotEmpty && !selectedDeck.isOwned) {
          selectedDeck = ownedDecks.first;
        }
        _isLoadingInventory = false;
      });
    } catch (e) {
      print('Error loading tarot decks: $e');
      setState(() {
        _isLoadingInventory = false;
        // Fallback: Only default deck is owned
        ownedDecks = [availableDecks[0].copyWith(isOwned: true)];
      });
    }
  }

  // Load card backs for selection
  Future<void> loadData() async {
    // Cards will be generated dynamically based on selected deck
    symbols = List.generate(10, (index) => 'card_back_$index');
  }

  // Check if cooldown is active
  Future<void> checkCooldown() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? lastSessionTimestamp = prefs.getInt('last_tarot_session');
    if (lastSessionTimestamp != null) {
      lastSessionTime = DateTime.fromMillisecondsSinceEpoch(lastSessionTimestamp);
      if (DateTime.now().difference(lastSessionTime).inHours < 24) { // Reduced to 24 hours
        setState(() {
          isCooldownActive = true;
        });
      }
    }
  }

  // Handle the user asking a question
  void askQuestion() {
    question = questionController.text.trim();
    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a question first')),
      );
      return;
    }

    symbolFadeController.forward(from: 0.0);
    playShuffleSound();
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        selectedSymbolsCount = 0;
        selectedSymbols.clear();
      });
    });
  }

  // Randomly pick card positions to display (but all show same card back)
  List<String> getRandomCardBacks() {
    // Generate 10 card positions, all will show the same card back image
    return List.generate(10, (index) => selectedDeck.cardBackImagePath);
  }

  // Handle selecting cards
  void selectSymbol(String cardBack) {
    if (selectedSymbolsCount >= 3) return;
    
    setState(() {
      selectedSymbols.add('card_${selectedSymbolsCount + 1}'); // Store unique identifier
      selectedSymbolsCount++;
      if (selectedSymbolsCount == 3) {
        proceedWithTarotCards();
      }
    });
    playSelectSymbolSound();
  }

  // Start the tarot card reading
  void proceedWithTarotCards() {
    setState(() {
      isShuffling = true;
    });

    playShuffleSound();

    Future.delayed(Duration(seconds: 3), () {
      Random random = Random();
      
      // Generate different card images for each drawn card
      List<String> cardImages = [];
      List<String> cardMeanings = [];
      List<int> usedCardNumbers = [];
      
      // Determine card range based on selected deck
      int maxCards = selectedDeck.cardMeanings.length;
      
      // Select 3 different random card numbers
      while (cardImages.length < 3) {
        int cardNumber = random.nextInt(maxCards) + 1;
        if (!usedCardNumbers.contains(cardNumber)) {
          usedCardNumbers.add(cardNumber);
          String cardPath = selectedDeck.cardFrontImagePath.replaceAll('tarot_front1.png', 'tarot_front$cardNumber.png');
          cardImages.add(cardPath);
          // Get the corresponding meaning (cardNumber - 1 because array is 0-indexed)
          cardMeanings.add(selectedDeck.cardMeanings[cardNumber - 1]);
        }
      }
      
      setState(() {
        drawnCards = cardImages;
        drawnCardMeanings = cardMeanings;
        isShuffling = false;
      });

      responseFadeController.forward(from: 0.0);
      playRevealCardSound();
      saveSessionTime();
    });
  }

  // Generate dynamic tarot response
  String getDynamicTarotResponse(String question) {
    String response = "";
    String questionLower = question.toLowerCase();

    if (questionLower.contains(RegExp(r'career|work|job|profession'))) {
      response = "The cards reveal insight into your career path:\n\n";
    } else if (questionLower.contains(RegExp(r'love|relationship|romance|heart'))) {
      response = "The cards speak of matters of the heart:\n\n";
    } else if (questionLower.contains(RegExp(r'money|finance|wealth|prosperity'))) {
      response = "The cards illuminate your financial future:\n\n";
    } else if (questionLower.contains(RegExp(r'health|wellness|healing'))) {
      response = "The cards offer guidance for your wellbeing:\n\n";
    } else {
      response = "The mystical cards reveal:\n\n";
    }

    response += "🔮 Past Influences: ${drawnCardMeanings[0]}\n\n";
    response += "✨ Present Situation: ${drawnCardMeanings[1]}\n\n";
    response += "🌟 Future Guidance: ${drawnCardMeanings[2]}\n\n";
    response += "Remember, you hold the power to shape your destiny. The cards merely illuminate the path.";

    return response;
  }

  // Audio methods
  void playShuffleSound() {
    try {
      _audioPlayer.play(AssetSource('sounds/shuffle_sound.mp3'));
    } catch (e) {
      print('Error playing shuffle sound: $e');
    }
  }

  void playSelectSymbolSound() {
    try {
      _audioPlayer.play(AssetSource('sounds/select_symbol_sound.mp3'));
    } catch (e) {
      print('Error playing select sound: $e');
    }
  }

  void playRevealCardSound() {
    try {
      _audioPlayer.play(AssetSource('sounds/reveal_card_sound.mp3'));
    } catch (e) {
      print('Error playing reveal sound: $e');
    }
  }

  // Show card description dialog
  void showCardDescription(String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            'Card Insight',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            description,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: [
            TextButton(
              child: Text('Close', style: TextStyle(color: Colors.deepPurpleAccent)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  // Save session time for cooldown
  Future<void> saveSessionTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('last_tarot_session', DateTime.now().millisecondsSinceEpoch);
    setState(() {
      isCooldownActive = true;
    });
  }

  // Reset reading for new question
  void resetReading() {
    setState(() {
      selectedSymbolsCount = 0;
      selectedSymbols.clear();
      drawnCards.clear();
      drawnCardMeanings.clear();
      isShuffling = false;
    });
    symbolFadeController.reset();
    responseFadeController.reset();
  }

  @override
  void dispose() {
    symbolFadeController.dispose();
    cardFlipController.dispose();
    responseFadeController.dispose();
    _audioPlayer.dispose();
    questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D1117),
      appBar: AppBar(
        title: Text(
          'Crystal Tarot Reading',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: true,
        actions: [
          if (drawnCards.isNotEmpty)
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: resetReading,
              tooltip: 'New Reading',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Deck Selector
            Container(
              margin: EdgeInsets.only(bottom: 20),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_stories, color: Colors.deepPurpleAccent),
                      SizedBox(width: 8),
                      Text(
                        'Choose Your Deck',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  if (_isLoadingInventory)
                    Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent))
                  else
                    DropdownButtonFormField<TarotDeck>(
                      value: ownedDecks.contains(selectedDeck) ? selectedDeck : ownedDecks.first,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color(0xFF0D1117),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.deepPurpleAccent),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.deepPurpleAccent.withOpacity(0.5)),
                        ),
                      ),
                      dropdownColor: Color(0xFF1A1A2E),
                      style: TextStyle(color: Colors.white),
                      onChanged: (TarotDeck? newDeck) {
                        if (newDeck != null) {
                          setState(() {
                            selectedDeck = newDeck;
                          });
                        }
                      },
                      items: ownedDecks.map<DropdownMenuItem<TarotDeck>>((TarotDeck deck) {
                        return DropdownMenuItem<TarotDeck>(
                          value: deck,
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LazyAssetImage(
                                  assetPath: deck.icon,
                                  width: 30,
                                  height: 30,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  deck.name,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              if (deck.isOwned)
                                Icon(Icons.check_circle, color: Colors.green, size: 16),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  if (ownedDecks.length < availableDecks.length)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Visit the shop to unlock more mystical decks!',
                        style: TextStyle(
                          color: Colors.deepPurpleAccent,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Cooldown message or main content
            if (isCooldownActive) ...[
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF2D1B69).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.access_time, color: Colors.deepPurpleAccent, size: 48),
                    SizedBox(height: 16),
                    Text(
                      "The cosmic energies need time to realign",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Please wait 24 hours before seeking another reading",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Question Input
              Container(
                margin: EdgeInsets.only(bottom: 20),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ask the Universe',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: questionController,
                      style: TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Focus your mind and ask your question...',
                        hintStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Color(0xFF0D1117),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (value) => askQuestion(),
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: askQuestion,
                        icon: Icon(Icons.auto_fix_high),
                        label: Text('Consult the Cards'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Symbol Selection
              if (selectedSymbolsCount < 3 && symbolFadeController.value > 0) ...[
                Container(
                  margin: EdgeInsets.only(bottom: 20),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Select 3 Cards from the Deck',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Chosen: $selectedSymbolsCount/3',
                        style: TextStyle(color: Colors.deepPurpleAccent),
                      ),
                      SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5, // 5 cards per row, 2 rows = 10 total
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.7, // Card aspect ratio (height > width)
                        ),
                        itemCount: 10,
                        itemBuilder: (context, index) {
                          String cardId = 'card_${index + 1}';
                          bool isSelected = selectedSymbols.contains(cardId);
                          return GestureDetector(
                            onTap: () => selectSymbol(selectedDeck.cardBackImagePath),
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected 
                                    ? Colors.deepPurpleAccent 
                                    : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: Colors.deepPurpleAccent.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ] : null,
                              ),
                              child: Shimmer.fromColors(
                                baseColor: Colors.white,
                                highlightColor: Colors.deepPurpleAccent,
                                child: AnimatedOpacity(
                                  opacity: symbolFadeController.value,
                                  duration: Duration(milliseconds: 500),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LazyAssetImage(
                                      assetPath: selectedDeck.cardBackImagePath,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],

              // Card Reading Results
              if (selectedSymbolsCount == 3) ...[
                if (isShuffling) ...[
                  Container(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          color: Colors.deepPurpleAccent,
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 20),
                        Text(
                          "The cards are aligning with cosmic forces...",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ] else if (drawnCards.isNotEmpty) ...[
                  Container(
                    margin: EdgeInsets.only(bottom: 20),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Your Reading',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(3, (index) {
                            return GestureDetector(
                              onTap: () => showCardDescription(drawnCardMeanings[index]),
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.deepPurpleAccent.withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: LazyAssetImage(
                                        assetPath: drawnCards[index], // Use the actual drawn card image
                                        width: 80,
                                        height: 120,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    ['Past', 'Present', 'Future'][index],
                                    style: TextStyle(
                                      color: Colors.deepPurpleAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                        SizedBox(height: 20),
                        FadeTransition(
                          opacity: responseFadeController,
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFF0D1117),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.deepPurpleAccent.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              getDynamicTarotResponse(question),
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class LazyAssetImage extends StatefulWidget {
  final String assetPath;
  final double width;
  final double height;
  final BoxFit fit;

  const LazyAssetImage({
    super.key,
    required this.assetPath,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  });

  @override
  _LazyAssetImageState createState() => _LazyAssetImageState();
}

class _LazyAssetImageState extends State<LazyAssetImage> {
  late Future<void> _precacheFuture;

  @override
  void initState() {
    super.initState();
    _precacheFuture = precacheImage(AssetImage(widget.assetPath), context);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _precacheFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Image.asset(
            widget.assetPath,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.white54,
                  size: widget.width * 0.4,
                ),
              );
            },
          );
        } else {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: SizedBox(
                width: widget.width * 0.3,
                height: widget.width * 0.3,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.deepPurpleAccent,
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
