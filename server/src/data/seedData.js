export const initialFamilies = [
  {
    id: 'fam_mishra',
    name: 'Mishra Parivar',
    gotra: 'Kashyap',
    kuldevi: 'Vindhyavasini Mata',
    kuldevta: 'Baba Vishwanath',
    invite_code: 'MISHRA-7782',
    active: true,
    created_at: new Date('2024-03-12T10:00:00Z').toISOString()
  },
  {
    id: 'fam_sharma',
    name: 'Sharma Parivar',
    gotra: 'Bharadwaja',
    kuldevi: 'Maa Shakumbhari',
    kuldevta: 'Lord Shiva',
    invite_code: 'SHARMA-1092',
    active: true,
    created_at: new Date('2024-04-05T14:30:00Z').toISOString()
  },
  {
    id: 'fam_mukherjee',
    name: 'Mukherjee Parivar',
    gotra: 'Sandilya',
    kuldevi: 'Maa Durga',
    kuldevta: 'Lord Narayana',
    invite_code: 'MUKHERJEE-4410',
    active: false,
    created_at: new Date('2024-06-18T08:15:00Z').toISOString()
  }
];

export const initialUsers = [
  {
    id: 'usr_ramesh',
    email: 'demo@example.com',
    passwordHash: 'Virasat@2026', // Shared demo password
    full_name: 'Ramesh Mishra',
    role: 'family_admin',
    family_id: 'fam_mishra'
  },
  {
    id: 'usr_sunita',
    email: 'member@example.com',
    passwordHash: 'Virasat@2026',
    full_name: 'Sunita Mishra',
    role: 'member',
    family_id: 'fam_mishra'
  },
  {
    id: 'usr_super',
    email: 'super@example.com',
    passwordHash: 'Virasat@2026',
    full_name: 'Platform Super Admin',
    role: 'super_admin',
    family_id: null // Enforced by check constraint
  }
];

export const initialMembers = [
  { id: 'm1', family_id: 'fam_mishra', name: 'Ramesh Mishra', relation: 'Self / Family Admin', phone: '+91 98765 43210' },
  { id: 'm2', family_id: 'fam_mishra', name: 'Sunita Mishra', relation: 'Wife', phone: '+91 98765 43211' },
  { id: 'm3', family_id: 'fam_mishra', name: 'Malti Devi (Dadi)', relation: 'Grandmother', phone: '+91 98765 43212' },
  { id: 'm4', family_id: 'fam_mishra', name: 'Rajesh Mishra', relation: 'Younger Brother', phone: '+91 98765 43213' },
  { id: 'm5', family_id: 'fam_mishra', name: 'Ananya Mishra', relation: 'Daughter', phone: '+91 98765 43214' },
  { id: 'm6', family_id: 'fam_mishra', name: 'Arjun Mishra', relation: 'Son', phone: '+91 98765 43215' },
  { id: 'm7', family_id: 'fam_mishra', name: 'Pushpa Tiwari', relation: 'Bua ji', phone: '+91 98765 43216' },
  { id: 'm8', family_id: 'fam_mishra', name: 'Virendra Shukla', relation: 'Mama ji', phone: '+91 98765 43217' }
];

export const initialCategories = [
  { id: 'cat_birth', name: 'Child Birth (Sanskara)', phases: ['Chatti', 'Namkaran', 'Mundan', 'Annaprashan'], family_id: null },
  { id: 'cat_janeu', name: 'Sacred Thread (Janeu)', phases: ['Matrika Pujan', 'Yajnopavita', 'Bhiksha'], family_id: null },
  { id: 'cat_vivah', name: 'Wedding (Vivah)', phases: ['Roka', 'Haldi', 'Mehendi', 'Saptapadi', 'Vidaai'], family_id: null },
  { id: 'cat_festivals', name: 'Festivals & Vrats', phases: ['Karwa Chauth', 'Teej', 'Chhath', 'Diwali', 'Holi'], family_id: null },
  { id: 'cat_seasonal', name: 'Seasonal & Griha Pravesh', phases: ['Vastu Shanti', 'Navratri Sthapana'], family_id: null },
  { id: 'cat_pitru', name: 'Ancestral / Pitru Shradh', phases: ['Tarpan', 'Pinda Daan', 'Brahmin Bhojan'], family_id: null },
  { id: 'cat_kuldevi', name: 'Kuldevi & Kuldevta Pujan', phases: ['Chunari Arpan', 'Jaagran', 'Havan'], family_id: null },
  { id: 'cat_custom', name: 'Other Traditions', phases: ['Custom Rites', 'Gram Devta Pujan'], family_id: null }
];

export const initialRituals = [
  {
    id: 'rit_karwa',
    family_id: 'fam_mishra',
    title: 'Karwa Chauth',
    category: 'Festivals & Vrats',
    phase: 'Suhag Parv',
    status: 'approved',
    samagri: "Mitti ka Karwa\nChhalni (Traditional brass sieve)\nSargi ki Thaali\nSolah Shringar\nMustard oil deepak & cotton wicks\nAkshat & Roli\nRaw milk & Ganga jal",
    steps: "Brahma Muhurta Sargi before sunrise served by Saas ji\nSankalp & Nirjala Vrat\nEvening Katha & Karwa rotation 7 times\nArghya to Moon through sieve and breaking fast",
    relative_roles: "Saas ji: Prepares morning sargi and blessings\nBhabhi ji: Leads ceremonial rotation of thalis\nNanad: Receives evening baya\nHusband: Offers first sip of water upon moon sighting",
    audio_paths: ['/assets/audio/karwa_geet.mp3'],
    songs: "करवा माता री आरती (Sung by Malti Devi Dadi)",
    additional_info: "Fast is broken only after moon sighting through the chhalni.",
    created_at: new Date('2024-10-10T16:00:00Z').toISOString()
  },
  {
    id: 'rit_teej',
    family_id: 'fam_mishra',
    title: 'Hariyali Teej',
    category: 'Festivals & Vrats',
    phase: 'Monsoon Shringaar',
    status: 'draft',
    samagri: "Clay idols of Shiva & Parvati\nBel patra & Dhatura\nGreen bangles & fresh mehendi cone\nGhewar\nSindhara hamper",
    steps: "Mehendi application and garden swing decoration\nReceiving Sindhara from maternal home\nHartalika Shiva-Parvati Pujan and singing Teej Malhar",
    relative_roles: "Nani ji: Sends auspicious Sindhara hamper\nChachi ji: Applies intricate mehendi\nElder Sister: Leads chorus of folk songs",
    audio_paths: ['/assets/audio/teej_malhar.mp3'],
    songs: "झूला झूलो री राधे रानी",
    additional_info: "Green leheriya attire worn by all family women.",
    created_at: new Date('2024-08-18T11:00:00Z').toISOString()
  },
  {
    id: 'rit_chhath',
    family_id: 'fam_mishra',
    title: 'Chhath Mahaparv',
    category: 'Festivals & Vrats',
    phase: 'Surya Upasana',
    status: 'approved',
    samagri: "Daura (Bamboo basket)\nSoop (Woven tray)\nThekua prashad\nGanna with leaves\nDaab Nimbu, Haldi & Ginger\nMitti ke diye",
    steps: "Day 1: Nahay Khay with sattvik Lauki-Bhaat\nDay 2: Kharna fast broken with Rasiyaav\nDay 3: Sandhya Arghya at sunset riverbank\nDay 4: Usha Arghya to rising sun and Paran",
    relative_roles: "Dadi / Vrati: 36-hour waterless penance\nSons & Nephews: Carry the Daura on head to the river\nDaughters-in-law: Bake Thekua on clay chulha",
    audio_paths: ['/assets/audio/chhath_geet.mp3'],
    songs: "काँच ही बाँस के बहँगिया",
    additional_info: "Purity and bronze utensils observed strictly.",
    created_at: new Date('2024-11-06T09:00:00Z').toISOString()
  }
];

export const initialRecipes = [
  {
    id: 'rec_fenia',
    ritual_id: 'rit_karwa',
    family_id: 'fam_mishra',
    name: 'Sargi ki Meethi Fenia & Mathri',
    ingredients: "1 cup roasted vermicelli (Fenia)\n1 litre full cream milk\n1/4 cup crushed almonds, pistachios & cashews\n1/2 tsp crushed cardamom\n1 cup whole wheat flour for mathri\n2 tbsp desi ghee",
    method: "Simmer milk until thick and creamy. Add fenia, cardamom, and saffron strands. Fry nuts in ghee and garnish. Serve hot at 4:30 AM before sunrise."
  },
  {
    id: 'rec_ghewar',
    ritual_id: 'rit_teej',
    family_id: 'fam_mishra',
    name: 'Authentic Rabdi Malai Ghewar',
    ingredients: "2 cups all-purpose flour\n1/2 cup solid desi ghee\nIce cubes\nSugar syrup with saffron\nThick kesar rabdi",
    method: "Whip ghee with ice cubes until fluffy white. Add flour and ice water gradually. Fry batter in piping hot ghee into a honeycomb lattice. Dip in syrup and top with rich rabdi."
  },
  {
    id: 'rec_thekua',
    ritual_id: 'rit_chhath',
    family_id: 'fam_mishra',
    name: "Grandmother's Crispy Thekua",
    ingredients: "2 cups coarse whole wheat flour\n1 cup melted jaggery\n1/4 cup dry coconut slivers\n1 tbsp crushed fennel seeds (saunf)\nDesi ghee for deep frying",
    method: "Knead flour firmly with melted jaggery and ghee moyan. Shape using traditional wooden sancha and deep fry in pure ghee on low flame until mahogany gold."
  }
];

export const initialOrders = [
  {
    id: 'ord_demo_1',
    family_id: 'fam_mishra',
    ritual_keys: ['rit_karwa', 'rit_chhath'],
    amount: 598,
    discount: 0,
    status: 'paid',
    created_at: new Date('2024-09-01T10:00:00Z').toISOString()
  }
];

export const initialMemories = [
  {
    id: 'mem_1',
    family_id: 'fam_mishra',
    title: "Diwali at Dadi's ancestral home in Varanasi",
    type: 'story',
    media_path: '/assets/images/memory_diwali.png',
    caption: '108 mustard oil lamps lit by Dadi along the courtyard parapet.',
    year: '1984',
    author_name: 'Ramesh Mishra',
    created_at: new Date('2024-10-01T12:00:00Z').toISOString()
  }
];
