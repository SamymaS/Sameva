import { useState } from 'react';
import { motion } from 'motion/react';
import type { UserData, Page } from '../App';
import { HeaderBar } from './HeaderBar';
import sanctuaryBg from 'figma:asset/03d246e43912467c3303b8a0425b51ce68bda6c1.png';

interface CustomizationV2Props {
  userData: UserData;
  onNavigate: (page: Page) => void;
}

type CustomTab = 'character' | 'companion' | 'decor';
type Rarity = 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary';

interface CustomItem {
  id: string;
  rarity: Rarity;
  icon: string;
}

const rarityColors = {
  common: { bg: 'from-gray-400 to-gray-500', border: 'border-gray-400' },
  uncommon: { bg: 'from-green-400 to-green-600', border: 'border-green-500' },
  rare: { bg: 'from-blue-400 to-blue-600', border: 'border-blue-500' },
  epic: { bg: 'from-purple-400 to-purple-600', border: 'border-purple-500' },
  legendary: { bg: 'from-yellow-400 to-yellow-600', border: 'border-yellow-500' },
};

const hairItems: CustomItem[] = [
  { id: 'h1', rarity: 'common', icon: '👩‍🦰' },
  { id: 'h2', rarity: 'uncommon', icon: '👩‍🦰' },
  { id: 'h3', rarity: 'rare', icon: '👩‍🦰' },
  { id: 'h4', rarity: 'epic', icon: '👩‍🦰' },
  { id: 'h5', rarity: 'legendary', icon: '👩‍🦰' },
];

const outfitItems: CustomItem[] = [
  { id: 'o1', rarity: 'common', icon: '👘' },
  { id: 'o2', rarity: 'uncommon', icon: '👘' },
  { id: 'o3', rarity: 'rare', icon: '👘' },
  { id: 'o4', rarity: 'epic', icon: '👘' },
  { id: 'o5', rarity: 'legendary', icon: '👘' },
];

const staffItems: CustomItem[] = [
  { id: 's1', rarity: 'common', icon: '🪄' },
  { id: 's2', rarity: 'uncommon', icon: '🪄' },
  { id: 's3', rarity: 'rare', icon: '🪄' },
  { id: 's4', rarity: 'epic', icon: '🪄' },
  { id: 's5', rarity: 'legendary', icon: '🪄' },
];

export function CustomizationV2({ userData, onNavigate }: CustomizationV2Props) {
  const [activeTab, setActiveTab] = useState<CustomTab>('character');
  const [selectedHair, setSelectedHair] = useState('h1');
  const [selectedOutfit, setSelectedOutfit] = useState('o1');
  const [selectedStaff, setSelectedStaff] = useState('s1');

  return (
    <div className="relative w-full h-full overflow-hidden">
      {/* Background */}
      <div className="absolute inset-0">
        <img 
          src={sanctuaryBg} 
          alt="Background" 
          className="w-full h-full object-cover blur-sm"
        />
        <div className="absolute inset-0 bg-black/50" />
      </div>

      {/* Header */}
      <HeaderBar userData={userData} onNavigate={onNavigate} />

      {/* Modal Container */}
      <div className="relative z-10 h-full flex items-center justify-center px-4 py-24">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.4 }}
          className="relative w-full max-w-md"
        >
          {/* Wooden/Golden ornate frame */}
          <div className="relative bg-gradient-to-br from-amber-900 via-amber-800 to-amber-950 rounded-3xl p-1 shadow-2xl">
            {/* Inner lighter wood border */}
            <div className="relative bg-gradient-to-br from-amber-700 via-amber-600 to-amber-800 rounded-[22px] p-3">
              {/* Content area */}
              <div className="relative bg-gradient-to-br from-[#D4AF37] via-[#C19A3B] to-[#A67C00] rounded-2xl p-0.5">
                <div className="bg-[#1A3A3A] rounded-2xl overflow-hidden">
                  
                  {/* Title Badge */}
                  <div className="relative pt-4 pb-2">
                    <div className="mx-auto w-64 h-10 relative">
                      {/* Golden badge background */}
                      <svg viewBox="0 0 250 40" className="absolute inset-0 w-full h-full">
                        <defs>
                          <linearGradient id="badgeGold" x1="0%" y1="0%" x2="100%" y2="100%">
                            <stop offset="0%" stopColor="#F4E4C1" />
                            <stop offset="50%" stopColor="#D4AF37" />
                            <stop offset="100%" stopColor="#C19A3B" />
                          </linearGradient>
                        </defs>
                        <path
                          d="M 20,5 L 230,5 L 240,20 L 230,35 L 20,35 L 10,20 Z"
                          fill="url(#badgeGold)"
                        />
                        {/* Decorative diamonds */}
                        <path d="M 5,20 L 15,15 L 25,20 L 15,25 Z" fill="#C19A3B" />
                        <path d="M 245,20 L 235,15 L 225,20 L 235,25 Z" fill="#C19A3B" />
                      </svg>
                      
                      <h2 className="absolute inset-0 flex items-center justify-center text-amber-900 text-xl font-fantasy">
                        Personalisation
                      </h2>
                    </div>
                  </div>

                  {/* Preview Area */}
                  <div className="px-4 pb-3">
                    <div className="relative h-32 rounded-xl overflow-hidden border-2 border-cyan-500/30">
                      <img 
                        src={sanctuaryBg} 
                        alt="Preview" 
                        className="w-full h-full object-cover"
                      />
                      <div className="absolute inset-0 bg-gradient-to-b from-transparent via-black/20 to-black/40" />
                      
                      {/* Mini character preview */}
                      <div className="absolute inset-0 flex items-center justify-center">
                        <div className="text-4xl">🧙‍♀️</div>
                      </div>
                    </div>
                  </div>

                  {/* Tabs */}
                  <div className="px-4 flex gap-2 mb-3">
                    {[
                      { id: 'character' as CustomTab, label: 'Personnage' },
                      { id: 'companion' as CustomTab, label: 'Familier' },
                      { id: 'decor' as CustomTab, label: 'Décor' },
                    ].map((tab) => (
                      <button
                        key={tab.id}
                        onClick={() => setActiveTab(tab.id)}
                        className={`flex-1 h-9 rounded-t-xl font-semibold text-sm transition-all duration-300 ${
                          activeTab === tab.id
                            ? 'bg-[#FFFAF0] text-amber-900'
                            : 'bg-gradient-to-br from-amber-800/60 to-amber-900/60 text-amber-200 hover:from-amber-700/60 hover:to-amber-800/60'
                        }`}
                      >
                        {tab.label}
                      </button>
                    ))}
                  </div>

                  {/* Content Panel - Parchment style */}
                  <div className="px-4 pb-4">
                    <div className="bg-[#FFFAF0] rounded-2xl p-4 max-h-80 overflow-y-auto">
                      
                      {activeTab === 'character' && (
                        <div className="space-y-4">
                          {/* Cheveux */}
                          <div>
                            <div className="flex items-center justify-center mb-3">
                              <div className="flex-1 h-px bg-amber-300/40" />
                              <h3 className="px-3 text-amber-900 font-semibold">Cheveux</h3>
                              <div className="flex-1 h-px bg-amber-300/40" />
                            </div>
                            
                            <div className="grid grid-cols-5 gap-2">
                              {hairItems.map((item) => (
                                <button
                                  key={item.id}
                                  onClick={() => setSelectedHair(item.id)}
                                  className={`relative aspect-square rounded-lg bg-gradient-to-br ${rarityColors[item.rarity].bg} p-0.5 hover:scale-105 active:scale-95 transition-transform duration-200`}
                                >
                                  <div className={`w-full h-full rounded-lg bg-[#F5F5DC] flex items-center justify-center border-2 ${rarityColors[item.rarity].border} ${selectedHair === item.id ? 'ring-2 ring-white ring-offset-2 ring-offset-[#FFFAF0]' : ''}`}>
                                    <span className="text-2xl">{item.icon}</span>
                                  </div>
                                </button>
                              ))}
                            </div>
                          </div>

                          {/* Tenue */}
                          <div>
                            <div className="flex items-center justify-center mb-3">
                              <div className="flex-1 h-px bg-amber-300/40" />
                              <h3 className="px-3 text-amber-900 font-semibold">Tenue</h3>
                              <div className="flex-1 h-px bg-amber-300/40" />
                            </div>
                            
                            <div className="grid grid-cols-5 gap-2">
                              {outfitItems.map((item) => (
                                <button
                                  key={item.id}
                                  onClick={() => setSelectedOutfit(item.id)}
                                  className={`relative aspect-square rounded-lg bg-gradient-to-br ${rarityColors[item.rarity].bg} p-0.5 hover:scale-105 active:scale-95 transition-transform duration-200`}
                                >
                                  <div className={`w-full h-full rounded-lg bg-[#F5F5DC] flex items-center justify-center border-2 ${rarityColors[item.rarity].border} ${selectedOutfit === item.id ? 'ring-2 ring-white ring-offset-2 ring-offset-[#FFFAF0]' : ''}`}>
                                    <span className="text-2xl">{item.icon}</span>
                                  </div>
                                </button>
                              ))}
                            </div>
                          </div>

                          {/* Bâton */}
                          <div>
                            <div className="flex items-center justify-center mb-3">
                              <div className="flex-1 h-px bg-amber-300/40" />
                              <h3 className="px-3 text-amber-900 font-semibold">Bâton</h3>
                              <div className="flex-1 h-px bg-amber-300/40" />
                            </div>
                            
                            <div className="grid grid-cols-5 gap-2">
                              {staffItems.map((item) => (
                                <button
                                  key={item.id}
                                  onClick={() => setSelectedStaff(item.id)}
                                  className={`relative aspect-square rounded-lg bg-gradient-to-br ${rarityColors[item.rarity].bg} p-0.5 hover:scale-105 active:scale-95 transition-transform duration-200`}
                                >
                                  <div className={`w-full h-full rounded-lg bg-[#F5F5DC] flex items-center justify-center border-2 ${rarityColors[item.rarity].border} ${selectedStaff === item.id ? 'ring-2 ring-white ring-offset-2 ring-offset-[#FFFAF0]' : ''}`}>
                                    <span className="text-2xl">{item.icon}</span>
                                  </div>
                                </button>
                              ))}
                            </div>
                          </div>
                        </div>
                      )}

                      {activeTab === 'companion' && (
                        <div className="text-center py-8 text-amber-700">
                          <div className="text-4xl mb-2">🦊</div>
                          <p className="text-sm">Familiers à venir...</p>
                        </div>
                      )}

                      {activeTab === 'decor' && (
                        <div className="text-center py-8 text-amber-700">
                          <div className="text-4xl mb-2">🏛️</div>
                          <p className="text-sm">Décorations à venir...</p>
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Validate Button */}
                  <div className="px-4 pb-4">
                    <button
                      onClick={() => onNavigate('sanctuary')}
                      className="relative w-full h-12 group"
                    >
                      {/* Golden button shape */}
                      <svg viewBox="0 0 300 48" className="absolute inset-0 w-full h-full">
                        <defs>
                          <linearGradient id="btnGold" x1="0%" y1="0%" x2="0%" y2="100%">
                            <stop offset="0%" stopColor="#F4E4C1" />
                            <stop offset="50%" stopColor="#D4AF37" />
                            <stop offset="100%" stopColor="#C19A3B" />
                          </linearGradient>
                        </defs>
                        <path
                          d="M 20,0 L 280,0 Q 300,10 300,24 Q 300,38 280,48 L 20,48 Q 0,38 0,24 Q 0,10 20,0"
                          fill="url(#btnGold)"
                          className="group-hover:opacity-90 transition-opacity"
                        />
                        <path
                          d="M 25,5 L 275,5 Q 293,12 293,24 Q 293,36 275,43 L 25,43 Q 7,36 7,24 Q 7,12 25,5"
                          fill="#C19A3B"
                          opacity="0.3"
                        />
                      </svg>
                      
                      <span className="absolute inset-0 flex items-center justify-center text-amber-900 font-semibold text-lg">
                        Valider
                      </span>
                    </button>
                  </div>

                </div>
              </div>
            </div>
          </div>

          {/* Decorative corner ornaments */}
          <div className="absolute -top-2 -left-2 w-8 h-8 bg-gradient-to-br from-yellow-400 to-yellow-600 rounded-full border-2 border-yellow-300" />
          <div className="absolute -top-2 -right-2 w-8 h-8 bg-gradient-to-br from-yellow-400 to-yellow-600 rounded-full border-2 border-yellow-300" />
          <div className="absolute -bottom-2 -left-2 w-8 h-8 bg-gradient-to-br from-yellow-400 to-yellow-600 rounded-full border-2 border-yellow-300" />
          <div className="absolute -bottom-2 -right-2 w-8 h-8 bg-gradient-to-br from-yellow-400 to-yellow-600 rounded-full border-2 border-yellow-300" />
        </motion.div>
      </div>
    </div>
  );
}