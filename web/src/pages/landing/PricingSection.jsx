import { ShieldCheck } from 'lucide-react';
import { Link } from '../../lib/router';
import { starterRituals } from '../../data/exampleFamily';

const entries = [
  {
    title: 'One ritual, recorded in full',
    detail: 'Steps, samagri, who does what, the food and the songs. Download it as a PDF.',
    amount: '₹299',
    unit: 'per ritual'
  },
  {
    title: 'Family Heirloom Edition',
    detail: 'Your rituals printed as a cloth-bound hardback, family name in gold foil.',
    amount: '₹2,499',
    unit: 'with the book'
  }
];

export default function PricingSection() {
  return (
    <section id="pricing" className="band band--cloth" aria-labelledby="pricing-title">
      <div className="wrap pricing">
        <div className="leaf pricing-sheet">
          <h2 id="pricing-title">Pay once per ritual. Keep it forever.</h2>

          <table className="hisaab">
            <caption className="sr-only">Prices</caption>
            <tbody>
              {entries.map((e) => (
                <tr key={e.title}>
                  <th scope="row">
                    <strong>{e.title}</strong>
                    <span>{e.detail}</span>
                  </th>
                  <td>
                    <strong className="num">{e.amount}</strong>
                    <span>{e.unit}</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          <p className="guarantee">
            <ShieldCheck size={22} aria-hidden="true" />
            Full refund if your elders are not moved by the book.
          </p>

          <div className="starters">
            <p className="field-label">Start with a ritual your family already performs</p>
            <ul>
              {starterRituals.slice(0, 4).map((r) => (
                <li key={r.title}>
                  <Link to={`/family?mode=new&ritual=${encodeURIComponent(r.title)}`} className="starter">
                    <span className="deva" lang="hi">{r.hindi}</span>
                    <span>{r.title}</span>
                  </Link>
                </li>
              ))}
              <li>
                <Link to="/family?mode=new" className="starter starter--own">Your own…</Link>
              </li>
            </ul>
          </div>
        </div>

        <figure className="book-photo">
          <img
            src="/assets/images/heirloom_book.jpg"
            alt="The printed Hamari Virasat book, cloth-bound with gold foil lettering"
            loading="lazy"
          />
          <figcaption>The printed book: made from the rituals you record.</figcaption>
        </figure>
      </div>
    </section>
  );
}
