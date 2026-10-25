import { usePath } from './lib/router';
import { SessionProvider } from './context/SessionContext';
import LandingPage from './pages/landing/LandingPage';
import FamilyPage from './pages/family/FamilyPage';
import AdminPage from './pages/admin/AdminPage';

const routes = {
  '/': LandingPage,
  '/family': FamilyPage,
  '/admin': AdminPage
};

export default function App() {
  const path = usePath();
  const Page = routes[path] || LandingPage;
  return (
    <SessionProvider>
      <Page />
    </SessionProvider>
  );
}
