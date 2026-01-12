import { useState } from 'react';
import { motion } from 'motion/react';
import { User, Sparkles, Home, ChevronRight } from 'lucide-react';
import type { UserData, InventoryItem } from '../App';

interface CustomizationProps {
  userData: UserData;
  inventory: InventoryItem[];
  onUpdateAvatar: (updates: Partial<UserData['avatar']>) => void;
}

type CustomizationTab = 'avatar' | 'sanctuary';

export function Customization({ userData, inventory, onUpdateAvatar }: CustomizationProps) {
  const [activeTab, setActiveTab] = useState<CustomizationTab>('avatar');
  const [previewAvatar, setPreviewAvatar] = useState(userData.avatar);

  const tabs = [
    { id: 'avatar' as CustomizationTab, label: 'Avatar', icon: User },
    { id: 'sanctuary' as CustomizationTab, label: 'Sanctuaire', icon: Home },
  ];

  const equippedItems = inventory.filter(item => item.equipped);
  const availableOutfits = inventory.filter(item => item.type === 'outfit');
  const availableAuras = inventory.filter(item => item.type === 'aura');
  const availableDecorations = inventory.filter(item => item.type === 'decoration');

  return (
    <div className="h-full flex flex-col px-4 pt-6 pb-20 overflow-y-auto">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="mb-6"
      >
        <h1 className="text-cream-100 text-2xl tracking-wide mb-1">Personnalisation</h1>
        <p className="text-purple-300/60 text-sm">Exprime ton essence</p>
      </motion.div>

      {/* Tabs */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.1 }}
        className="flex gap-3 mb-6"
      >
        {tabs.map((tab) => {
          const isActive = activeTab === tab.id;
          const Icon = tab.icon;
          
          return (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`relative flex-1 flex items-center justify-center gap-2 py-3 rounded-xl transition-all duration-300 ${
                isActive
                  ? 'bg-gradient-to-br from-purple-500/30 to-blue-500/30 border border-purple-400/50 shadow-[0_0_20px_rgba(168,85,247,0.4)]'
                  : 'bg-purple-950/20 border border-purple-500/20 hover:border-purple-400/40'
              }`}
            >
              <Icon size={20} className={isActive ? 'text-purple-200' : 'text-purple-400/60'} />
              <span className={isActive ? 'text-purple-100' : 'text-purple-400/60'}>
                {tab.label}
              </span>
              
              {isActive && (
                <motion.div
                  layoutId="customizationTab"
                  className="absolute inset-0 bg-gradient-to-br from-purple-400/20 to-blue-400/20 rounded-xl -z-10 blur-xl"
                  initial={false}
                  transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                />
              )}
            </button>
          );
        })}
      </motion.div>

      {/* Preview */}
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.5, delay: 0.2 }}
        className="relative mb-8 aspect-square rounded-3xl overflow-hidden border border-purple-400/20 shadow-[0_8px_40px_rgba(139,92,246,0.3)]"
      >
        {/* Background */}
        <div className="absolute inset-0 bg-gradient-to-b from-indigo-950/80 via-purple-900/60 to-violet-950/80">
          {/* Starry effect */}
          <div className="absolute inset-0 opacity-40">
            {Array.from({ length: 30 }).map((_, i) => (
              <motion.div
                key={i}
                className="absolute w-1 h-1 bg-white rounded-full"
                style={{
                  left: `${Math.random() * 100}%`,
                  top: `${Math.random() * 100}%`,
                }}
                animate={{
                  opacity: [0.2, 1, 0.2],
                }}
                transition={{
                  duration: Math.random() * 3 + 2,
                  repeat: Infinity,
                  delay: Math.random() * 2,
                }}
              />
            ))}
          </div>

          {/* Light rays */}
          <div className="absolute top-0 left-1/4 w-1 h-full bg-gradient-to-b from-blue-300/20 via-purple-300/10 to-transparent blur-sm" />
          <div className="absolute top-0 right-1/3 w-1 h-full bg-gradient-to-b from-purple-300/20 via-blue-300/10 to-transparent blur-sm" />
        </div>

        {/* Avatar Preview */}
        {activeTab === 'avatar' && (
          <div className="absolute inset-0 flex items-end justify-center pb-12">
            <motion.div
              className="relative"
              animate={{ y: [0, -8, 0] }}
              transition={{ duration: 4, repeat: Infinity, ease: 'easeInOut' }}
            >
              {/* Aura */}
              <motion.div
                className="absolute inset-0 -m-12 bg-gradient-radial from-purple-400/40 via-blue-400/20 to-transparent rounded-full blur-2xl"
                animate={{ scale: [1, 1.15, 1], opacity: [0.4, 0.6, 0.4] }}
                transition={{ duration: 3, repeat: Infinity }}
              />
              
              <div className="relative w-32 h-32 bg-gradient-to-br from-purple-300/30 to-blue-300/30 rounded-full border-2 border-purple-300/50 shadow-[0_0_40px_rgba(216,180,254,0.6)] flex items-center justify-center backdrop-blur-sm">
                <span className="text-6xl">🧙‍♀️</span>
              </div>
            </motion.div>
          </div>
        )}

        {/* Sanctuary Preview */}
        {activeTab === 'sanctuary' && (
          <div className="absolute inset-0 flex items-center justify-center">
            <span className="text-8xl opacity-50">🏛️</span>
          </div>
        )}
      </motion.div>

      {/* Customization Options */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.3 }}
      >
        {activeTab === 'avatar' && (
          <div className="space-y-6">
            {/* Outfits */}
            <div>
              <h3 className="text-purple-200 mb-3 flex items-center gap-2">
                <Sparkles size={18} />
                <span>Tenues</span>
              </h3>
              <div className="grid grid-cols-4 gap-3">
                {availableOutfits.map((item) => (
                  <button
                    key={item.id}
                    onClick={() => onUpdateAvatar({ outfit: item.id })}
                    className={`aspect-square p-3 rounded-xl border transition-all duration-300 ${
                      item.equipped
                        ? 'bg-gradient-to-br from-purple-500/30 to-blue-500/30 border-purple-400/50 shadow-[0_0_20px_rgba(168,85,247,0.4)]'
                        : 'bg-purple-950/20 border-purple-500/20 hover:border-purple-400/40'
                    }`}
                  >
                    <div className="w-full h-full flex items-center justify-center">
                      <span className="text-3xl">{item.icon}</span>
                    </div>
                  </button>
                ))}
              </div>
            </div>

            {/* Auras */}
            <div>
              <h3 className="text-purple-200 mb-3 flex items-center gap-2">
                <Sparkles size={18} />
                <span>Auras</span>
              </h3>
              <div className="grid grid-cols-4 gap-3">
                {availableAuras.map((item) => (
                  <button
                    key={item.id}
                    onClick={() => onUpdateAvatar({ aura: item.id })}
                    className={`aspect-square p-3 rounded-xl border transition-all duration-300 ${
                      item.equipped
                        ? 'bg-gradient-to-br from-purple-500/30 to-blue-500/30 border-purple-400/50 shadow-[0_0_20px_rgba(168,85,247,0.4)]'
                        : 'bg-purple-950/20 border-purple-500/20 hover:border-purple-400/40'
                    }`}
                  >
                    <div className="w-full h-full flex items-center justify-center">
                      <span className="text-3xl">{item.icon}</span>
                    </div>
                  </button>
                ))}
              </div>
            </div>
          </div>
        )}

        {activeTab === 'sanctuary' && (
          <div className="space-y-6">
            <div>
              <h3 className="text-purple-200 mb-3 flex items-center gap-2">
                <Home size={18} />
                <span>Décors</span>
              </h3>
              <div className="space-y-3">
                {availableDecorations.length === 0 ? (
                  <div className="text-center py-8 text-purple-300/40">
                    Aucune décoration disponible
                  </div>
                ) : (
                  availableDecorations.map((item) => (
                    <button
                      key={item.id}
                      className="w-full p-4 rounded-xl bg-gradient-to-br from-purple-900/30 to-blue-900/30 border border-purple-400/20 hover:border-purple-400/40 transition-all duration-300 flex items-center justify-between"
                    >
                      <div className="flex items-center gap-3">
                        <span className="text-3xl">{item.icon}</span>
                        <span className="text-purple-100">{item.name}</span>
                      </div>
                      <ChevronRight size={20} className="text-purple-400/60" />
                    </button>
                  ))
                )}
              </div>
            </div>
          </div>
        )}
      </motion.div>
    </div>
  );
}
