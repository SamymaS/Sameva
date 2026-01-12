import { motion } from 'motion/react';
import { Home, Scroll, Package, Users, Settings } from 'lucide-react';
import type { Page } from '../App';

interface NavigationBarProps {
  currentPage: Page;
  onNavigate: (page: Page) => void;
}

export function NavigationBar({ currentPage, onNavigate }: NavigationBarProps) {
  const navItems = [
    { id: 'sanctuary' as Page, icon: Home, label: 'Accueil' },
    { id: 'quests' as Page, icon: Scroll, label: 'Quêtes' },
    { id: 'inventory' as Page, icon: Package, label: 'Sac' },
    { id: 'social' as Page, icon: Users, label: 'Cercle' },
    { id: 'settings' as Page, icon: Settings, label: 'Réglages' },
  ];

  return (
    <motion.nav 
      className="fixed bottom-0 left-0 right-0 bg-gradient-to-t from-[#0a0e27]/95 via-[#1a1449]/90 to-transparent backdrop-blur-xl border-t border-purple-500/20 shadow-[0_-4px_30px_rgba(139,92,246,0.1)] touch-pan-x z-50"
      style={{ paddingBottom: 'max(0.5rem, env(safe-area-inset-bottom))' }}
      initial={{ y: 100 }}
      animate={{ y: 0 }}
      transition={{ duration: 0.5, ease: 'easeOut' }}
    >
      <div className="max-w-md mx-auto px-2 py-2">
        <div className="flex justify-around items-center">
          {navItems.map((item) => {
            const isActive = currentPage === item.id;
            const Icon = item.icon;
            
            return (
              <button
                key={item.id}
                onClick={() => onNavigate(item.id)}
                className="relative flex flex-col items-center gap-1 p-2 rounded-xl transition-all duration-300 active:scale-95"
              >
                {isActive && (
                  <motion.div
                    layoutId="activeTab"
                    className="absolute inset-0 bg-gradient-to-br from-purple-500/20 to-blue-500/20 rounded-xl"
                    initial={false}
                    transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                  />
                )}
                
                <motion.div
                  className="relative z-10"
                  animate={{
                    scale: isActive ? 1.1 : 1,
                    y: isActive ? -2 : 0,
                  }}
                  transition={{ duration: 0.3 }}
                >
                  <Icon 
                    size={22}
                    className={`transition-all duration-300 ${
                      isActive 
                        ? 'text-purple-300 drop-shadow-[0_0_8px_rgba(216,180,254,0.8)]' 
                        : 'text-purple-400/50'
                    }`}
                    strokeWidth={isActive ? 2.5 : 2}
                  />
                </motion.div>
                
                <span 
                  className={`text-[9px] transition-all duration-300 relative z-10 ${
                    isActive 
                      ? 'text-purple-200' 
                      : 'text-purple-400/40'
                  }`}
                >
                  {item.label}
                </span>

                {isActive && (
                  <motion.div
                    className="absolute -top-1 left-1/2 -translate-x-1/2 w-8 h-8 bg-purple-400/30 rounded-full blur-xl"
                    initial={{ opacity: 0, scale: 0 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ duration: 0.4 }}
                  />
                )}
              </button>
            );
          })}
        </div>
      </div>
    </motion.nav>
  );
}