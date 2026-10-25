import { useState } from 'react';
import { Check, Music, UtensilsCrossed } from 'lucide-react';
import { exampleFamily } from '../../data/exampleFamily';

export default function ExampleLedger({ ritualId, onSelect }) {
  const ritual = exampleFamily.rituals.find((r) => r.id === ritualId) || exampleFamily.rituals[0];
  const [ticked, setTicked] = useState({});

  const toggle = (key) => setTicked((t) => ({ ...t, [key]: !t[key] }));

  return (
    <section id="example" className="band band--paper" aria-labelledby="example-title">
      <div className="wrap">
        <div className="band-head">
          <h2 id="example-title">One page of a family book</h2>
          <p>This is the example Mishra family. Your book has your rituals, in your family’s words.</p>
        </div>

        <div className="book">
          <div className="book-tabs" role="tablist" aria-label="Rituals in the example book">
            {exampleFamily.rituals.map((r) => (
              <button
                key={r.id}
                role="tab"
                aria-selected={r.id === ritual.id}
                aria-controls="example-page"
                className="book-tab"
                onClick={() => onSelect(r.id)}
              >
                <span className="deva" lang="hi">{r.hindi}</span>
                <span>{r.title}</span>
              </button>
            ))}
          </div>

          <article id="example-page" className="leaf book-page" role="tabpanel" key={ritual.id}>
            <header className="page-head">
              <div>
                <h3>
                  {ritual.title} <span className="deva" lang="hi">{ritual.hindi}</span>
                </h3>
                <p className="page-provenance hand">
                  Told by {ritual.toldBy} · written down by {ritual.writtenBy}
                </p>
              </div>
              <span className={`stamp ${ritual.recorded ? 'stamp--done' : 'stamp--draft'}`}>
                {ritual.recorded ? 'Recorded' : 'In progress'}
              </span>
            </header>

            <h4 className="page-label">Vidhi <span className="deva" lang="hi">विधि</span></h4>
            <ol className="steps">
              {ritual.steps.map((s) => (
                <li key={s.title} className="step">
                  <span className="step-when">{s.when}</span>
                  <span className="step-body">
                    <strong>{s.title}</strong>
                    <span>{s.note}</span>
                  </span>
                </li>
              ))}
            </ol>

            <div className="page-columns">
              <div>
                <h4 className="page-label">Samagri <span className="deva" lang="hi">सामग्री</span></h4>
                <ul className="samagri">
                  {ritual.samagri.map((item) => {
                    const key = `${ritual.id}:${item}`;
                    return (
                      <li key={item}>
                        <button
                          className="samagri-item"
                          aria-pressed={!!ticked[key]}
                          onClick={() => toggle(key)}
                        >
                          <span className="tick" aria-hidden="true">{ticked[key] && <Check size={16} strokeWidth={3} />}</span>
                          {item}
                        </button>
                      </li>
                    );
                  })}
                </ul>
              </div>
              <div>
                <h4 className="page-label">Who does what</h4>
                <dl className="roles">
                  {ritual.roles.map((r) => (
                    <div key={r.who}>
                      <dt>{r.who}</dt>
                      <dd>{r.task}</dd>
                    </div>
                  ))}
                </dl>
              </div>
            </div>

            <footer className="page-foot">
              <p><UtensilsCrossed size={18} aria-hidden="true" /> <span>Made for it: <strong>{ritual.recipe}</strong></span></p>
              <p><Music size={18} aria-hidden="true" /> <span>Sung: <strong>{ritual.song.title}</strong>, {ritual.song.singer}, <span className="num">{ritual.song.length}</span></span></p>
            </footer>
          </article>
        </div>
      </div>
    </section>
  );
}
