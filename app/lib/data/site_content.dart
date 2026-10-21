// Everything the app borrows from hamarivirasat.in: the ritual catalogue with its
// sub-sections, pricing, and the copy for the info and support pages.

const int kPricePerRitual = 299;

const kSiteUrl = 'https://www.hamarivirasat.in';
const kSamplePdfUrl = '$kSiteUrl/sample-ritual-document.pdf';
const kPrivacyUrl = '$kSiteUrl/privacy';
const kTermsUrl = '$kSiteUrl/terms';
const kRefundUrl = '$kSiteUrl/refund-policy';
const kWhatsAppUrl = 'https://wa.me/919238820685';
const kCalendlyUrl = 'https://calendly.com/hamarivirasat712';
const kInstagramUrl = 'https://www.instagram.com/hamari.virasat';
const kFacebookUrl = 'https://www.facebook.com/share/1FWMe46RYn/';
const kBusinessHours =
    'We typically respond within 4-8 hours during business hours (Mon-Sat, 10 AM - 7 PM IST).';

/// How a sub-section of the documentation form is filled in.
enum SectionKind { title, profile, samagri, steps, food, roles, songs, photos, info, text }

class SubSection {
  final String name;
  final SectionKind kind;
  const SubSection(this.name, this.kind);
}

class RitualTemplate {
  final String key;
  final String stage; // Pre-birth, Post-birth, Initiation, Festival, Custom · DIY
  final String title;
  final String description;
  final List<String> subSectionNames; // as shown on the website
  final bool isDiy;

  const RitualTemplate({
    required this.key,
    required this.stage,
    required this.title,
    required this.description,
    required this.subSectionNames,
    this.isDiy = false,
  });

  /// The website's sub-sections, each mapped to the field it fills. The first samagri,
  /// steps, food, roles, songs, photos and information section go to the ritual's own
  /// fields; every other one is kept as free text under its name.
  List<SubSection> get subSections {
    final used = <SectionKind>{};
    final out = <SubSection>[];
    for (final raw in subSectionNames) {
      final name = raw.trim();
      var kind = _kindFor(name);
      if (kind != SectionKind.text && !used.add(kind)) kind = SectionKind.text;
      out.add(SubSection(name, kind));
    }
    return out;
  }
}

SectionKind _kindFor(String name) {
  final n = name.toLowerCase();
  if (n.contains('name the ritual')) return SectionKind.title;
  if (n.contains('ancestral profile')) return SectionKind.profile;
  if (n.contains('additional inf')) return SectionKind.info;
  if (n.contains('photo')) return SectionKind.photos;
  if (n.contains('samagri') && !n.contains('festival')) return SectionKind.samagri;
  if (n == 'ritual steps' || n == 'pooja steps' || n.contains('describe the steps')) {
    return SectionKind.steps;
  }
  if (n.contains('special foods') || n.contains('describe the food')) return SectionKind.food;
  if (n.contains('relative roles')) return SectionKind.roles;
  if (n.contains('song') || n.contains('bhajan')) return SectionKind.songs;
  return SectionKind.text;
}

const List<RitualTemplate> kCatalogue = [
  RitualTemplate(
    key: 'godbharai',
    stage: 'Pre-birth',
    title: 'GodBharai / Sadh',
    description:
        'The Godbharai ceremony blesses the expectant mother and invokes divine protection for both mother and child. Each element — from the Samagri to the songs sung by the women of the house — carries generations of meaning.',
    subSectionNames: [
      'Ancestral Profile',
      'Samagri & Offerings',
      'Ritual Steps',
      'Special Foods',
      'Relative Roles',
      'Ritual Songs (Geet)',
      'Photos',
      'Additional Information',
    ],
  ),
  RitualTemplate(
    key: 'chatti',
    stage: 'Post-birth',
    title: 'Chatti / Shashti Puja',
    description:
        "On the sixth day after birth, the Chatti Puja formally introduces the newborn to the family and the divine. The Mama's role, the naming ritual, and the songs of welcome are all meticulously observed.",
    subSectionNames: [
      'Samagri & Offerings',
      'Naming Ceremony',
      "Mama's Role",
      'Special Foods',
      'Ritual Steps',
      'Family Photos',
    ],
  ),
  RitualTemplate(
    key: 'janeu',
    stage: 'Initiation',
    title: 'Janeu / Upanayan',
    description:
        "The sacred thread ceremony initiates a young man into his spiritual duties. The Guru's instructions, the specific mantras of your lineage, and the roles of the extended family all deserve to be preserved in full.",
    subSectionNames: [
      'Samagri & Offerings',
      'Mantra Traditions',
      "Guru's Instructions",
      'Special Foods',
      'Ritual Steps',
    ],
  ),
  RitualTemplate(
    key: 'chhath',
    stage: 'Festival',
    title: 'Chhath Puja',
    description:
        'Chhath Puja is an ancient four-day Hindu festival dedicated to the Sun God (Surya) and Chhathi Maiya. Chhath is celebrated mainly in Bihar, Jharkhand, and eastern Uttar Pradesh to thank the setting Sun God and the rising Sun God for life on Earth, seek blessings for family health, and practice deep ritual purity.',
    subSectionNames: [
      'Pooja Samagri',
      'Attire',
      'Special Foods',
      'Receipe',
      'Ritual Steps Day 01',
      'Ritual Steps Day 02',
      'Ritual Steps Day 03',
      'Ritual Steps Day 04',
      'Family Photos',
      'Additional Information',
    ],
  ),
  RitualTemplate(
    key: 'ganapati',
    stage: 'Festival',
    title: 'Ganapati Puja',
    description:
        'The beloved celebration of Lord Ganesha in your home. The exact way your family prepares the modaks, decorates the mandap, and performs the aarti is a tradition unique to your household.',
    subSectionNames: [
      'Samagri & Offerings',
      'Decoration details',
      'Aarti & Bhajans',
      'Special Foods',
      'Ritual Steps',
      'Family Photos',
    ],
  ),
  RitualTemplate(
    key: 'navratri',
    stage: 'Festival',
    title: 'Navratri / Dussehra',
    description:
        'Nine nights of divine worship, culminating in Vijayadashami. Capture how your family observes the fasting rules, the Kanya Pujan, the Garba traditions, and the specific offerings made to the Goddess.',
    subSectionNames: [
      'Pre Pooja Preparation',
      'Pooja Samagri',
      'Pooja Steps',
      'Kalash Sthapana Vidhi',
      'Pooja Vidhi / Mantra',
      'Day wise Attire: e.g. Day 1... Day 2...',
      'Prasad',
      'Bhog',
      'Recipe',
      'Saptami Pooja',
      'MahaAshtami',
      'Navmi Pooja',
      'Kumari pooja',
      'Dashmi Pooja',
      'Ratri Pooja',
      'Hawan',
      'Aarti',
      'Additional Information',
    ],
  ),
  RitualTemplate(
    key: 'karwa_chauth',
    stage: 'Festival',
    title: 'Karwa Chauth',
    description:
        'The sacred fast for marital bliss. The specific items in the Sargi, the evening puja thali preparation, and the story reading are cherished practices passed down from mother-in-law to daughter-in-law.',
    subSectionNames: [
      'Samagri & Offerings',
      'Sargi details',
      'Evening Puja',
      'Special Foods',
      'Ritual Steps',
      'Family Photos',
    ],
  ),
  RitualTemplate(
    key: 'teej',
    stage: 'Festival',
    title: 'Teej (Hariyali/Haritalika)',
    description:
        'The vibrant celebration of monsoon and marital devotion. The swings, the green attire, the mehndi designs, and the traditional songs sung with family are memories worth keeping forever.',
    subSectionNames: [
      'Samagri & Offerings',
      'Attire & Mehndi',
      'Traditional Songs',
      'Special Foods',
      'Ritual Steps',
      'Family Photos',
    ],
  ),
  RitualTemplate(
    key: 'bhai_dooj',
    stage: 'Festival',
    title: 'Bhai Dooj / Chitragupta Pooja',
    description:
        'Bhai Dooj celebrates the timeless bond between brothers and sisters, a relationship woven with childhood memories, love, laughter, care, and togetherness.\n\nIn Hindu mythology, the festival is associated with the bond between Lord Yamraj and his sister Yamuna and is also linked to the story of Lord Krishna and his sister Subhadra. At its heart, Bhai Dooj celebrates the love and blessings that make family relationships precious.',
    subSectionNames: [
      'Pooja Samagri',
      'Festival Samagri for people',
      'Fasting Rules',
      'Special Foods',
      'Ritual Steps',
      'Pooja related image: Yam Pooja',
      'Songs sung',
      'Chitragupta Puja',
      'Pooja mantra',
      'Additional Information',
    ],
  ),
  RitualTemplate(
    key: 'diwali',
    stage: 'Festival',
    title: 'Diwali Pooja',
    description:
        'Devotees worship Goddess Lakshmi (the deity of wealth and prosperity) alongside Lord Ganesha (the remover of obstacles and lord of wisdom). In some traditions, Goddess Saraswati (knowledge) and Kubera (wealth keeper) are also invoked.',
    subSectionNames: [
      'Pre Pooja Preparation',
      'Pooja Samagri',
      'Festival Samagri e.g. Diya, light',
      'Attire to wear',
      'Laxmi Ganesh Vrat Katha',
      'Kalash Sthapana',
      'Aarti',
      'Hawan',
      'Commercial shop puja preparation',
      'Additional Information',
    ],
  ),
  RitualTemplate(
    key: 'diy',
    stage: 'Custom · DIY',
    title: 'DIY: Custom Family Ritual',
    description:
        'Every family carries ceremonies that belong only to them. If your family observes a ritual that is not in this list — document it here. You describe it, we preserve it exactly as you tell us.',
    subSectionNames: [
      'You name the ritual',
      'You list the Samagri',
      'You describe the steps',
      'You describe the Food',
      'You share the songs',
      'Add Photos',
      'Additional Information',
    ],
    isDiy: true,
  ),
];

RitualTemplate? templateFor(String key) {
  for (final t in kCatalogue) {
    if (t.key == key) return t;
  }
  return null;
}

/// Catalogue stages in the order the website lists them.
const kStages = ['Pre-birth', 'Post-birth', 'Initiation', 'Festival', 'Custom · DIY'];

class ComingSoon {
  final String key;
  final String stage;
  final String title;
  final String description;
  const ComingSoon(this.key, this.stage, this.title, this.description);
}

const List<ComingSoon> kComingSoon = [
  ComingSoon(
    'boy_wedding',
    'Wedding (Groom)',
    "Boy's Wedding",
    "The full set of groom-side ceremonies — Tilak, Baarat, Jaimala, and the post-wedding rituals specific to the groom's family.",
  ),
  ComingSoon(
    'girl_wedding',
    'Wedding (Bride)',
    "Girl's Wedding",
    "The bride-side ceremonies — Mehendi, Haldi, Sangeet, and the deeply emotional rituals that mark a daughter's departure.",
  ),
  ComingSoon(
    'last_rituals',
    'Ancestral',
    'Family Last Rituals',
    'The Antim Sanskar, the Dasah, the Terahvin — end-of-life ceremonies that carry profound meaning and deserve the most careful documentation.',
  ),
];

const kHowToStart = [
  'Select the rituals you want to be documented (₹299 each)',
  'Tap "Proceed to Payment" in the bar below',
  'Complete the payment to receive your personalised form',
];

const kIncluded = [
  'Your selected rituals — each one documented in full',
  'Complete Samagri list for each ceremony',
  "Ritual steps in your family's sequence",
  'Songs, prayers & mantras — as your family says them',
  "Every relative's role, captured precisely",
  'Gotra, Kuldevi & Kuldevta — your ancestral roots',
  'Photo integration with captions & context',
  'Beautifully formatted PDF heirloom document',
  'Delivered to your inbox within 7 days of form completion',
  'Save & resume — fill at your own pace over multiple sittings',
  'Secure Razorpay checkout',
  '7-day satisfaction guarantee',
  'Confirmation email instantly',
];

class TitledText {
  final String title;
  final String text;
  const TitledText(this.title, this.text);
}

const kWhyItMatters = [
  TitledText(
    'Time is not on our side',
    "Every elder who passes carries irreplaceable knowledge with them. The Mama's role, the exact Samagri list, the order of the Pheras - none of it is written down, and each generation knows a little less than the one before.",
  ),
  TitledText(
    'Photos fade. Memory fades faster.',
    'You have the photos, but who remembers what song was sung, or why the ritual was performed that way? Hamari Virasat captures the context, not just the image - so the meaning is never lost.',
  ),
  TitledText(
    'Your family is unique',
    'No two families celebrate a wedding the same way. The regional customs, the family-specific variations, the inside meanings - your rituals deserve to be documented in your words, not generic templates.',
  ),
];

const kHowItWorks = [
  TitledText(
    'Choose rituals/Festivals',
    'Select the rituals/festivals you want documented from the list. Pick one or as many as you like. If yours is not listed, select the custom option.',
  ),
  TitledText(
    'Treasure it effortlessly',
    'Take your time to fill out the form using the link provided. Once you submit all the information, we will send you draft version for approval.',
  ),
  TitledText(
    'Preserve it forever',
    'After your approval, you will receive a beautiful document to preserve, share and treasure.',
  ),
];

const kSaveAndResume =
    "Fill at your own pace — no rush, no deadline. After payment, you can save and resume your form any time. Gather your family, consult your elders, and come back when you're ready. Most families complete their form over 3–7 days.";

const kAboutParagraphs = [
  'We all carry a unique thread of heritage — the subtle fragrance of a morning puja, the authentic sequence of a ritual. Yet, too often, when the time comes to perform these precious traditions, we find ourselves confused, searching for answers, unsure of the steps.',
  'As families become nuclear and spread across the globe, the living libraries once held by our elders are quietly fading away.',
  "Hamari Virasat is that home. It is a secure, timeless digital space created for you to document, preserve, and honor your family's unique rituals and festivals.",
  "With Hamari Virasat, your family's traditions will never be forgotten. Through intuitive, step-by-step guided templates, we empower you to document, preserve, and keep your family's legacy alive forever.",
];

const kFoundersNote =
    "Hamari Virasat was born from this exact heartfelt realization. As a family person, I watched family gatherings get clouded by uncertainty and chaos, simply because no one could recall the authentic ways our elders celebrated life's milestones. I realized that without a home for our traditions, we risk losing not just the steps of a ritual, but the very essence of who we are.";

class Testimonial {
  final String quote;
  final String name;
  final String place;
  final String ritual;
  const Testimonial(this.quote, this.name, this.place, this.ritual);
}

const kTestimonials = [
  Testimonial(
    'My grandmother was the only one who knew all the Godbharai songs. When she passed, we thought we had lost them forever. Hamari Virasat helped us recover what we remembered and capture it properly. That document is now the most precious thing in our home.',
    'Priya Mehta',
    'Pune, Maharashtra',
    'Godbharai & Mundan',
  ),
  Testimonial(
    "We were planning my daughter's wedding and realised none of us agreed on the order of the Pheras. Everyone had a different memory. Hamari Virasat gave us a way to sit with the elders, record the right sequence, and now it's preserved for her children too.",
    'Rajesh Sharma',
    'Jaipur, Rajasthan',
    'Vivah Mandap & Pheras',
  ),
  Testimonial(
    "The intake form was so thoughtfully written and it felt like someone who truly understood our culture had designed it. It prompted questions I wouldn't have thought to ask. The final document made my parents cry when they read it.",
    'Ananya Krishnan',
    'Bengaluru, Karnataka',
    'Complete Heritage Record',
  ),
];

// The 13 questions are the website's. Its answers are loaded only when a question is
// opened in the browser, so these answers are written from the website's own copy.
const kFaq = [
  TitledText(
    'What is Hamari Virasat?',
    'A structured platform where Indian families can record the rituals that define them, from pre-birth to the ancestral rites, and preserve them in a form that lasts.',
  ),
  TitledText(
    'What format does the final document come in?',
    'A beautifully formatted PDF heirloom document that you can preserve, share and treasure. You can download a sample document before you commit to anything.',
  ),
  TitledText(
    'How long does it take to receive the finished document?',
    'Within 7 days of completing your form. We first send you a draft version for approval, and the final document follows after you approve it.',
  ),
  TitledText(
    'Can we add our own custom family rituals which are not listed?',
    'Yes. Choose "DIY: Custom Family Ritual". You name the ritual, list the samagri, describe the steps and the food, share the songs and add photos, and we preserve it exactly as you tell us.',
  ),
  TitledText(
    'How do you collect stories from your elders?',
    'Through a guided form with a section for each part of the ritual. Sit with your elders, ask the questions the form prompts, and write down or record what they say. You can save and come back as many times as you need.',
  ),
  TitledText(
    'Do my grandparents need to download a mobile app?',
    'No. One family member can fill in the form on their behalf while talking to them. Elders only need to share what they remember.',
  ),
  TitledText(
    'What if my elders speak a regional language or dialect?',
    'Write it the way your family says it. Songs, prayers and mantras are kept in your own words, and you can attach a voice recording so the original is never lost.',
  ),
  TitledText(
    'Are there hidden charges for custom rituals?',
    'No. Every ritual, including a custom one, is ₹299. One-time payment, no subscription, no hidden costs.',
  ),
  TitledText(
    "Who has access to our family's data and media?",
    'Only your family. What you record is 100% personal and private: other families cannot see it, and it is used only to prepare your own document.',
  ),
  TitledText(
    'Can my siblings or cousins contribute to the same vault?',
    'Yes. Share your family invite code from the Family tab. Relatives who join with it see and add to the same family space.',
  ),
  TitledText(
    "What if I don't remember all the details of a ritual?",
    'Fill in what you know and save it as a draft. Come back after speaking to your elders. Most families complete their form over 3 to 7 days.',
  ),
  TitledText(
    'What is your refund policy?',
    'There is a 7-day satisfaction guarantee. The full refund policy is on our website and linked from this page.',
  ),
  TitledText(
    'How do I get started with the onboarding process?',
    'Choose the rituals you want documented, complete the payment, and your personalised form opens right away. You can also book a free 15-minute call and we will walk you through it.',
  ),
];

const kEnquiryTopics = [
  'General enquiry about the service',
  'Understanding what is documented',
  'Question about a specific ritual',
  'Pricing and payment options',
  'Custom or regional ritual not in standard list',
  'Other',
];

const kAfterYouWrite = [
  TitledText('We read it personally', 'Every enquiry is read by the team — no bots, no auto-responders.'),
  TitledText(
    'You hear back within 1 business day',
    "Usually much sooner. We take every family's question seriously.",
  ),
  TitledText(
    'No pressure, ever',
    'We will answer honestly — even if the answer is "we are not the right fit."',
  ),
];

const kCallPoints = [
  "We'll walk you through exactly what's included",
  'Answer any questions about your specific rituals',
  'Explain how the intake form works, step by step',
  'No pressure, no obligation',
];
