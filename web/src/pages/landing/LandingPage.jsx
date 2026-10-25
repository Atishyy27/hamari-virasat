import { useState } from 'react';
import SiteHeader from '../../components/layout/SiteHeader';
import SiteFooter from '../../components/layout/SiteFooter';
import HeroSpread from './HeroSpread';
import ExampleLedger from './ExampleLedger';
import PrivacySection from './PrivacySection';
import EldersSection from './EldersSection';
import PricingSection from './PricingSection';
import { exampleFamily } from '../../data/exampleFamily';

export default function LandingPage() {
  const [ritualId, setRitualId] = useState(exampleFamily.rituals[0].id);

  const openRitual = (id) => {
    setRitualId(id);
    document.getElementById('example')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  };

  return (
    <>
      <SiteHeader />
      <main>
        <HeroSpread onOpenRitual={openRitual} />
        <ExampleLedger ritualId={ritualId} onSelect={setRitualId} />
        <PrivacySection />
        <EldersSection />
        <PricingSection />
      </main>
      <SiteFooter />
    </>
  );
}
