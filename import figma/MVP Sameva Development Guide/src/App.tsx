import { useState, useEffect } from "react";
import { motion, AnimatePresence } from "motion/react";
import { SplashScreen } from "./components/SplashScreen";
import { Onboarding } from "./components/Onboarding";
import { Authentication } from "./components/Authentication";
import { SanctuaryV2 } from "./components/SanctuaryV2";
import { QuestCreation } from "./components/QuestCreation";
import { QuestList } from "./components/QuestList";
import { InventoryV2 } from "./components/InventoryV2";
import { CustomizationV2 } from "./components/CustomizationV2";
import { Market } from "./components/Market";
import { Invocation } from "./components/Invocation";
import { MiniGame } from "./components/MiniGame";
import { Profile } from "./components/Profile";
import { Social } from "./components/Social";
import { Settings } from "./components/Settings";
import { NavigationBar } from "./components/NavigationBar";
import { ParticleEffect } from "./components/ParticleEffect";
import { PhoneFrame } from "./components/PhoneFrame";

export type Page =
  | "sanctuary"
  | "quests"
  | "quest-creation"
  | "inventory"
  | "customization"
  | "market"
  | "invocation"
  | "minigame"
  | "profile"
  | "social"
  | "settings";
export type AppState = "splash" | "onboarding" | "auth" | "app";

export interface UserData {
  name: string;
  level: number;
  xp: number;
  maxXp: number;
  nextLevelXp: number;
  gold: number;
  coins: number;
  gems: number;
  avatar: {
    body: string;
    hair: string;
    outfit: string;
    aura: string;
  };
  sanctuary: string;
  companion: string;
}

export interface Quest {
  id: string;
  title: string;
  description: string;
  category:
    | "study"
    | "sport"
    | "selfcare"
    | "creative"
    | "social";
  difficulty: "easy" | "medium" | "hard";
  rewards: {
    xp: number;
    gold: number;
    items?: string[];
  };
  status: "active" | "completed" | "upcoming";
  progress?: number;
  deadline?: string;
}

export interface InventoryItem {
  id: string;
  name: string;
  type:
    | "outfit"
    | "aura"
    | "decoration"
    | "companion"
    | "consumable";
  rarity:
    | "common"
    | "rare"
    | "epic"
    | "legendary"
    | "uncommon"
    | "mythic";
  equipped: boolean;
  icon: string;
}

function App() {
  const [appState, setAppState] = useState<AppState>("splash");
  const [currentPage, setCurrentPage] =
    useState<Page>("sanctuary");

  // Simulate splash screen
  useEffect(() => {
    if (appState === "splash") {
      const timer = setTimeout(() => {
        setAppState("onboarding");
      }, 3000);
      return () => clearTimeout(timer);
    }
  }, [appState]);

  const [userData, setUserData] = useState<UserData>({
    name: "Voyageur",
    level: 12,
    xp: 750,
    maxXp: 1000,
    nextLevelXp: 1500,
    gold: 2840,
    coins: 500,
    gems: 45,
    avatar: {
      body: "default",
      hair: "long-blue",
      outfit: "mystic-robe",
      aura: "lunar-glow",
    },
    sanctuary: "moonlit-ruins",
    companion: "spirit-fox",
  });

  const [quests, setQuests] = useState<Quest[]>([
    {
      id: "1",
      title: "Méditation matinale",
      description:
        "Prendre 15 minutes pour méditer au lever du soleil",
      category: "selfcare",
      difficulty: "easy",
      rewards: { xp: 50, gold: 20 },
      status: "active",
      progress: 0,
    },
    {
      id: "2",
      title: "Réviser le chapitre 5",
      description:
        "Terminer les exercices et faire une fiche de révision",
      category: "study",
      difficulty: "medium",
      rewards: { xp: 120, gold: 50, items: ["study-scroll"] },
      status: "active",
      progress: 60,
    },
    {
      id: "3",
      title: "Course de 5km",
      description: "Courir 5km en maintenant un bon rythme",
      category: "sport",
      difficulty: "hard",
      rewards: {
        xp: 200,
        gold: 100,
        items: ["stamina-potion"],
      },
      status: "active",
      progress: 100,
    },
  ]);

  const [inventory, setInventory] = useState<InventoryItem[]>([
    {
      id: "1",
      name: "Robe Mystique",
      type: "outfit",
      rarity: "rare",
      equipped: true,
      icon: "👘",
    },
    {
      id: "2",
      name: "Aura Lunaire",
      type: "aura",
      rarity: "epic",
      equipped: true,
      icon: "✨",
    },
    {
      id: "3",
      name: "Renard Spirituel",
      type: "companion",
      rarity: "legendary",
      equipped: true,
      icon: "🦊",
    },
    {
      id: "4",
      name: "Potion de Stamina",
      type: "consumable",
      rarity: "common",
      equipped: false,
      icon: "🧪",
    },
    {
      id: "5",
      name: "Couronne Céleste",
      type: "outfit",
      rarity: "legendary",
      equipped: false,
      icon: "👑",
    },
    {
      id: "6",
      name: "Aura Dorée",
      type: "aura",
      rarity: "uncommon",
      equipped: false,
      icon: "💫",
    },
    {
      id: "7",
      name: "Épée Flamboyante",
      type: "outfit",
      rarity: "mythic",
      equipped: false,
      icon: "⚔️",
    },
    {
      id: "8",
      name: "Chat Astral",
      type: "companion",
      rarity: "epic",
      equipped: false,
      icon: "🐱",
    },
  ]);

  const completeQuest = (questId: string) => {
    const quest = quests.find((q) => q.id === questId);
    if (!quest || quest.status === "completed") return;

    // Update quest status
    setQuests((prev) =>
      prev.map((q) =>
        q.id === questId
          ? {
              ...q,
              status: "completed" as const,
              progress: 100,
            }
          : q,
      ),
    );

    // Add rewards
    setUserData((prev) => {
      const newXp = prev.xp + quest.rewards.xp;
      const levelUp = newXp >= prev.maxXp;

      return {
        ...prev,
        xp: levelUp ? newXp - prev.maxXp : newXp,
        level: levelUp ? prev.level + 1 : prev.level,
        gold: prev.gold + quest.rewards.gold,
      };
    });
  };

  const addQuest = (
    quest: Omit<Quest, "id" | "status" | "progress">,
  ) => {
    const newQuest: Quest = {
      ...quest,
      id: Date.now().toString(),
      status: "active",
      progress: 0,
    };
    setQuests((prev) => [...prev, newQuest]);
  };

  const pageVariants = {
    initial: { opacity: 0, scale: 0.98 },
    animate: {
      opacity: 1,
      scale: 1,
      transition: { duration: 0.4, ease: "easeOut" },
    },
    exit: {
      opacity: 0,
      scale: 1.02,
      transition: { duration: 0.3, ease: "easeIn" },
    },
  };

  // Render app states
  if (appState === "splash") {
    return (
      <PhoneFrame>
        <SplashScreen />
      </PhoneFrame>
    );
  }

  if (appState === "onboarding") {
    return (
      <PhoneFrame>
        <Onboarding onComplete={() => setAppState("auth")} />
      </PhoneFrame>
    );
  }

  if (appState === "auth") {
    return (
      <PhoneFrame>
        <Authentication onLogin={() => setAppState("app")} />
      </PhoneFrame>
    );
  }

  return (
    <PhoneFrame>
      <div className="relative w-full h-full bg-gradient-to-b from-[#0a0e27] via-[#1a1449] to-[#2d1b4e] overflow-hidden">
        {/* Background particles */}
        <ParticleEffect />

        {/* Ambient glow effects */}
        <div className="absolute top-20 left-10 w-64 h-64 bg-purple-500/20 rounded-full blur-[100px] animate-pulse" />
        <div
          className="absolute bottom-40 right-10 w-80 h-80 bg-blue-500/15 rounded-full blur-[120px] animate-pulse"
          style={{ animationDelay: "1s" }}
        />

        {/* Main content */}
        <div className="relative z-10 flex flex-col h-full">
          <AnimatePresence mode="wait">
            <motion.div
              key={currentPage}
              variants={pageVariants}
              initial="initial"
              animate="animate"
              exit="exit"
              className="flex-1 overflow-y-auto"
            >
              {currentPage === "sanctuary" && (
                <SanctuaryV2
                  userData={userData}
                  onNavigate={setCurrentPage}
                  activeQuests={quests.filter(
                    (q) => q.status === "active",
                  )}
                />
              )}
              {currentPage === "quest-creation" && (
                <QuestCreation
                  onNavigate={setCurrentPage}
                  onCreateQuest={addQuest}
                />
              )}
              {currentPage === "quests" && (
                <QuestList
                  quests={quests}
                  onCompleteQuest={completeQuest}
                  onNavigate={setCurrentPage}
                />
              )}
              {currentPage === "inventory" && (
                <InventoryV2
                  userData={userData}
                  inventory={inventory}
                  onNavigate={setCurrentPage}
                  onEquipItem={(itemId) => {
                    setInventory((prev) =>
                      prev.map((item) =>
                        item.id === itemId
                          ? {
                              ...item,
                              equipped: !item.equipped,
                            }
                          : item,
                      ),
                    );
                  }}
                />
              )}
              {currentPage === "customization" && (
                <CustomizationV2
                  userData={userData}
                  onNavigate={setCurrentPage}
                />
              )}
              {currentPage === "market" && (
                <Market
                  userData={userData}
                  onPurchase={(cost) => {
                    setUserData((prev) => ({
                      ...prev,
                      gold: prev.gold - cost,
                    }));
                  }}
                />
              )}
              {currentPage === "invocation" && (
                <Invocation
                  userData={userData}
                  onInvoke={(cost) => {
                    setUserData((prev) => ({
                      ...prev,
                      gems: prev.gems - cost,
                    }));
                  }}
                  onReceiveItem={(item) => {
                    setInventory((prev) => [...prev, item]);
                  }}
                />
              )}
              {currentPage === "minigame" && (
                <MiniGame
                  onReward={(gold, xp) => {
                    setUserData((prev) => ({
                      ...prev,
                      gold: prev.gold + gold,
                      xp: prev.xp + xp,
                    }));
                  }}
                />
              )}
              {currentPage === "profile" && (
                <Profile userData={userData} />
              )}
              {currentPage === "social" && (
                <Social userData={userData} />
              )}
              {currentPage === "settings" && (
                <Settings userData={userData} />
              )}
            </motion.div>
          </AnimatePresence>

          {/* Navigation */}
          <NavigationBar
            currentPage={currentPage}
            onNavigate={setCurrentPage}
          />
        </div>
      </div>
    </PhoneFrame>
  );
}

export default App;