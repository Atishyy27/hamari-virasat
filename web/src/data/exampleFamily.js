// Sample family shown on the public site. Always labelled "Example": not a customer.
export const exampleFamily = {
  name: 'Mishra Parivar',
  place: 'Varanasi',
  gotra: 'Vatsa',
  kuldevi: 'Maa Vindhyavasini',
  rituals: [
    {
      id: 'karwa-chauth',
      title: 'Karwa Chauth',
      hindi: 'करवा चौथ',
      tithi: 'Kartik Krishna 4',
      toldBy: 'Malti Devi (Dadi)',
      writtenBy: 'Ananya',
      recorded: true,
      steps: [
        { when: 'Before sunrise', title: 'Saas ji serves the sargi', note: 'Fenia, dry fruits and sweets, eaten before the fast.' },
        { when: 'Morning', title: 'Sankalp and nirjala vrat', note: 'Bath, then the vow of a waterless fast.' },
        { when: 'Sunset', title: 'Katha and karwa exchange', note: 'Women sit in a circle and pass the thalis seven times.' },
        { when: 'Moonrise', title: 'Arghya to the moon', note: 'See the moon through the chhalni, then break the fast.' }
      ],
      samagri: ['Mitti ka karwa', 'Chhalni', 'Sargi thaali', 'Solah shringar', 'Diya and wicks', 'Akshat and roli'],
      roles: [
        { who: 'Saas ji', task: 'Prepares the sargi' },
        { who: 'Bhabhi ji', task: 'Leads the thali rotation' },
        { who: 'Nanad', task: 'Receives the baya' }
      ],
      recipe: 'Sargi ki fenia and mathri',
      song: { title: 'Karwa Mata ki Aarti', singer: 'Malti Devi (Dadi)', length: '3:42' }
    },
    {
      id: 'hariyali-teej',
      title: 'Hariyali Teej',
      hindi: 'हरियाली तीज',
      tithi: 'Shravan Shukla 3',
      toldBy: 'Pushpa Tiwari (Bua ji)',
      writtenBy: 'Ramesh',
      recorded: false,
      steps: [
        { when: 'Morning', title: 'Mehendi and the jhula', note: 'The swing is hung with marigolds in the courtyard.' },
        { when: 'Afternoon', title: 'Sindhara from the maika', note: 'Ghewar and green bangles arrive from Nani ji.' },
        { when: 'Evening', title: 'Shiva–Parvati pujan', note: 'The Hartalika katha is read aloud.' }
      ],
      samagri: ['Clay Shiva–Parvati', 'Bel patra', 'Green bangles', 'Ghewar'],
      roles: [
        { who: 'Nani ji', task: 'Sends the sindhara' },
        { who: 'Chachi ji', task: 'Applies the mehendi' },
        { who: 'Elder sister', task: 'Leads the malhar' }
      ],
      recipe: 'Rabdi ghewar',
      song: { title: 'Jhula Jhulo Radha Rani', singer: 'Pushpa Tiwari (Bua ji)', length: '4:15' }
    },
    {
      id: 'chhath',
      title: 'Chhath Mahaparv',
      hindi: 'छठ महापर्व',
      tithi: 'Kartik Shukla 6',
      toldBy: 'Malti Devi (Dadi)',
      writtenBy: 'Arjun',
      recorded: true,
      steps: [
        { when: 'Day 1', title: 'Nahay khay', note: 'A sattvik meal of lauki and bhaat.' },
        { when: 'Day 2', title: 'Kharna', note: 'The fast is broken with rasiyaav.' },
        { when: 'Day 3, sunset', title: 'Sandhya arghya', note: 'Offering to the setting sun at the ghat.' },
        { when: 'Day 4, sunrise', title: 'Usha arghya and paran', note: 'Offering to the rising sun, then the fast ends.' }
      ],
      samagri: ['Daura', 'Soop', 'Thekua', 'Ganna', 'Mitti ke diye'],
      roles: [
        { who: 'Dadi', task: 'Keeps the 36-hour fast' },
        { who: 'Sons', task: 'Carry the daura to the river' },
        { who: 'Bahus', task: 'Make thekua on the chulha' }
      ],
      recipe: 'Dadi’s crispy thekua',
      song: { title: 'Kaanch hi baans ke bahangiya', singer: 'Malti Devi (Dadi)', length: '5:08' }
    },
    {
      id: 'namkaran',
      title: 'Namkaran',
      hindi: 'नामकरण संस्कार',
      tithi: '12th day after birth',
      toldBy: 'Sunita',
      writtenBy: 'Sunita',
      recorded: false,
      steps: [
        { when: 'Morning', title: 'Havan', note: 'The family priest lights the fire.' },
        { when: 'Midday', title: 'The name is whispered', note: 'Bua ji says the name into the baby’s right ear.' },
        { when: 'Afternoon', title: 'Bhoj', note: 'Family and neighbours are fed.' }
      ],
      samagri: ['Havan samagri', 'Kansa thaali', 'New clothes for the baby', 'Panchamrit'],
      roles: [
        { who: 'Bua ji', task: 'Chooses and says the name' },
        { who: 'Dadi', task: 'Holds the baby' }
      ],
      recipe: 'Panchamrit and gond laddu',
      song: { title: 'Sohar', singer: 'Pushpa Tiwari (Bua ji)', length: '2:56' }
    }
  ]
};

// Rituals families most often start with; picking one prefills the first entry.
export const starterRituals = [
  { title: 'Karwa Chauth', hindi: 'करवा चौथ' },
  { title: 'Chhath', hindi: 'छठ' },
  { title: 'Diwali Lakshmi Pujan', hindi: 'लक्ष्मी पूजन' },
  { title: 'Hariyali Teej', hindi: 'हरियाली तीज' },
  { title: 'Mundan', hindi: 'मुंडन' },
  { title: 'Namkaran', hindi: 'नामकरण' },
  { title: 'Haldi', hindi: 'हल्दी' },
  { title: 'Satyanarayan Katha', hindi: 'सत्यनारायण कथा' }
];
