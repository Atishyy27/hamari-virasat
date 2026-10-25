// The diya mark: a flame between two leaves over a lamp. Brand mark, kept from the app.
export function DiyaMark({ size = 40, className = '' }) {
  return (
    <svg
      className={`diya-mark ${className}`}
      width={size}
      height={size}
      viewBox="0 0 40 40"
      aria-hidden="true"
    >
      <circle cx="20" cy="20" r="19" fill="var(--paper)" stroke="var(--haldi)" strokeWidth="1.5" />
      <path d="M20 7C21.8 11.2 24.5 14.5 24.5 17.8C24.5 20.3 22.5 22.2 20 22.2C17.5 22.2 15.5 20.3 15.5 17.8C15.5 14.5 18.2 11.2 20 7Z" fill="var(--haldi-deep)" />
      <path d="M18.5 21C14 21 8.5 24 8.5 29C13 31.5 19 28 20 24.5C19.5 23 19 22 18.5 21Z" fill="var(--cloth)" />
      <path d="M21.5 21C26 21 31.5 24 31.5 29C27 31.5 21 28 20 24.5C20.5 23 21 22 21.5 21Z" fill="var(--cloth)" />
      <path d="M13 29.5C16 32 24 32 27 29.5" stroke="var(--cloth-deep)" strokeWidth="1.6" strokeLinecap="round" fill="none" />
    </svg>
  );
}

export default function DiyaLogo({ size = 40 }) {
  return (
    <span className="brand">
      <DiyaMark size={size} />
      <span className="brand-words">
        <span className="brand-name">Hamari Virasat</span>
        <span className="brand-deva deva" lang="hi">हमारी विरासत</span>
      </span>
    </span>
  );
}
