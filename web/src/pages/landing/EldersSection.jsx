import { Mic, MessageCircle, Keyboard, PhoneCall } from 'lucide-react';

const ways = [
  { icon: Mic, title: 'Just speak', text: 'Press record and let Dadi sing or explain.' },
  { icon: MessageCircle, title: 'Send a WhatsApp voice note', text: 'We add it to your family book.' },
  { icon: Keyboard, title: 'Grandchildren type it', text: 'They write down what elders tell them.' },
  { icon: PhoneCall, title: 'We call them', text: 'Our team phones your elders and writes it down.' }
];

export default function EldersSection() {
  return (
    <section id="elders" className="band band--paper" aria-labelledby="elders-title">
      <div className="wrap elders">
        <div className="band-head band-head--left">
          <h2 id="elders-title">Dadi doesn’t need to learn an app.</h2>
          <p>Her memory is what matters. Getting it written down is our job.</p>
        </div>
        <ul className="ways">
          {ways.map(({ icon: Icon, title, text }) => (
            <li key={title}>
              <Icon size={24} aria-hidden="true" />
              <div>
                <h3>{title}</h3>
                <p>{text}</p>
              </div>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
