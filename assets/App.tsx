import { useState } from "react";
import { Sanctuary } from "./components/Sanctuary";
import { QuestCreation } from "./components/QuestCreation";
import { Marketplace } from "./components/Marketplace";
import { Summoning } from "./components/Summoning";
import { Customization } from "./components/Customization";
import { MiniGame } from "./components/MiniGame";
import { Navigation } from "./components/Navigation";

export default function App() {
  const [currentPage, setCurrentPage] = useState("sanctuary");

  const renderPage = () => {
    switch (currentPage) {
      case "sanctuary":
        return <Sanctuary onNavigate={setCurrentPage} />;
      case "quests":
        return <QuestCreation />;
      case "marketplace":
        return <Marketplace />;
      case "summoning":
        return <Summoning />;
      case "customization":
        return <Customization />;
      case "minigame":
        return <MiniGame />;
      default:
        return <Sanctuary onNavigate={setCurrentPage} />;
    }
  };

  return (
    <div className="min-h-screen">
      {renderPage()}
      <Navigation currentPage={currentPage} onPageChange={setCurrentPage} />
    </div>
  );
}