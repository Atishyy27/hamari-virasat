const rules = [
  {
    title: 'Private, even from us',
    text: 'Our own team cannot open your rituals, recipes, songs or member list. The database refuses it.'
  },
  {
    title: 'No family tree',
    text: 'Everyone is one line in the list. Nobody is ranked above anyone else.'
  },
  {
    title: 'Food stays with its ritual',
    text: 'Thekua sits under Chhath, fenia under Karwa Chauth. Nothing floats loose.'
  }
];

export default function PrivacySection() {
  return (
    <section id="privacy" className="band band--cloth" aria-labelledby="privacy-title">
      <div className="wrap">
        <div className="band-head">
          <h2 id="privacy-title">Only your family can read it.</h2>
          <p>Three rules are built into the database itself, not written into a promise.</p>
        </div>
        <ul className="rules">
          {rules.map((r) => (
            <li key={r.title}>
              <h3>{r.title}</h3>
              <p>{r.text}</p>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
