import { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { ChevronDown } from 'lucide-react';
import type { UserData, Page, InventoryItem } from '../App';
import { HeaderBar } from './HeaderBar';
import sanctuaryBg from 'figma:asset/03d246e43912467c3303b8a0425b51ce68bda6c1.png';

interface InventoryV2Props {
  userData: UserData;
  inventory: InventoryItem[];
  onNavigate: (page: Page) => void;
  onEquipItem: (itemId: string) => void;
}

type FilterTab = 'all' | 'weapons' | 'armors' | 'potions' | 'misc';

const rarityColors = {
  common: { bg: 'from-gray-400 to-gray-500', border: 'border-gray-400' },
  uncommon: { bg: 'from-green-400 to-green-600', border: 'border-green-500' },
  rare: { bg: 'from-blue-400 to-blue-600', border: 'border-blue-500' },
  epic: { bg: 'from-purple-400 to-purple-600', border: 'border-purple-500' },
  legendary: { bg: 'from-yellow-400 to-yellow-600', border: 'border-yellow-500' },
  mythic: { bg: 'from-pink-400 to-pink-600', border: 'border-pink-500' },
};

// Mock inventory items
const mockItems: (InventoryItem & { quantity: number })[] = [
  { id: '1', name: 'Grande Potion', type: 'consumable', rarity: 'rare', icon: '🧪', equipped: false, quantity: 1 },
  { id: '2', name: 'Parchemin Vierge', type: 'consumable', rarity: 'common', icon: '📜', equipped: false, quantity: 1 },
  { id: '3', name: 'Parchemin Ancien', type: 'consumable', rarity: 'common', icon: '📜', equipped: false, quantity: 1 },
  { id: '4', name: 'Potion Verte', type: 'consumable', rarity: 'uncommon', icon: '🧪', equipped: false, quantity: 3 },
  { id: '5', name: 'Orbe Vert', type: 'consumable', rarity: 'uncommon', icon: '🔮', equipped: false, quantity: 2 },
  { id: '6', name: 'Parchemin Vert', type: 'consumable', rarity: 'uncommon', icon: '📜', equipped: false, quantity: 2 },
  { id: '7', name: 'Parchemin Bleu', type: 'consumable', rarity: 'uncommon', icon: '📜', equipped: false, quantity: 3 },
  { id: '8', name: 'Épée Simple', type: 'weapon', rarity: 'common', icon: '⚔️', equipped: false, quantity: 1 },
  { id: '9', name: 'Épée Bleue', type: 'weapon', rarity: 'rare', icon: '⚔️', equipped: false, quantity: 2 },
  { id: '10', name: 'Épée Dorée', type: 'weapon', rarity: 'rare', icon: '⚔️', equipped: false, quantity: 3 },
  { id: '11', name: 'Épée Rare', type: 'weapon', rarity: 'rare', icon: '⚔️', equipped: false, quantity: 2 },
  { id: '12', name: 'Tunique Simple', type: 'outfit', rarity: 'rare', icon: '👘', equipped: false, quantity: 3 },
  { id: '13', name: 'Armure Grise', type: 'outfit', rarity: 'common', icon: '🛡️', equipped: false, quantity: 1 },
  { id: '14', name: 'Armure Épique', type: 'outfit', rarity: 'epic', icon: '🛡️', equipped: false, quantity: 3 },
  { id: '15', name: 'Livre Doré', type: 'consumable', rarity: 'legendary', icon: '📖', equipped: false, quantity: 5 },
  { id: '16', name: 'Parchemin Violet', type: 'consumable', rarity: 'epic', icon: '📜', equipped: false, quantity: 3 },
  { id: '17', name: 'Flèche Violette', type: 'weapon', rarity: 'epic', icon: '🏹', equipped: false, quantity: 1 },
  { id: '18', name: 'Rune Grise', type: 'consumable', rarity: 'rare', icon: '🗿', equipped: false, quantity: 6 },
  { id: '19', name: 'Orbe Doré', type: 'consumable', rarity: 'legendary', icon: '🔮', equipped: false, quantity: 1 },
  { id: '20', name: 'Engrenage Doré', type: 'consumable', rarity: 'legendary', icon: '⚙️', equipped: false, quantity: 1 },
  { id: '21', name: 'Plume Rare', type: 'consumable', rarity: 'rare', icon: '🪶', equipped: false, quantity: 1 },
  { id: '22', name: 'Pierre Grise', type: 'consumable', rarity: 'rare', icon: '💎', equipped: false, quantity: 1 },
  { id: '23', name: 'Cristal Bleu', type: 'consumable', rarity: 'rare', icon: '💎', equipped: false, quantity: 1 },
  { id: '24', name: 'Gemme Verte', type: 'consumable', rarity: 'uncommon', icon: '💎', equipped: false, quantity: 1 },
  { id: '25', name: 'Cristal Doré', type: 'consumable', rarity: 'legendary', icon: '💎', equipped: false, quantity: 1 },
];

export function InventoryV2({ userData, inventory, onNavigate, onEquipItem }: InventoryV2Props) {
  const [activeFilter, setActiveFilter] = useState<FilterTab>('all');
  const [selectedItem, setSelectedItem] = useState<(InventoryItem & { quantity: number }) | null>(mockItems[0]);

  const filterTabs = [
    { id: 'all' as FilterTab, label: 'Tout' },
    { id: 'weapons' as FilterTab, label: 'Armes' },
    { id: 'armors' as FilterTab, label: 'Armures' },
    { id: 'potions' as FilterTab, label: 'Potions' },
    { id: 'misc' as FilterTab, label: 'Divers' },
  ];

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
          className="relative w-full max-w-md h-[calc(100%-120px)]"
        >
          {/* Wooden/Golden ornate frame */}
          <div className="relative bg-gradient-to-br from-amber-900 via-amber-800 to-amber-950 rounded-3xl p-1 shadow-2xl h-full">
            <div className="relative bg-gradient-to-br from-amber-700 via-amber-600 to-amber-800 rounded-[22px] p-3 h-full">
              <div className="relative bg-gradient-to-br from-[#D4AF37] via-[#C19A3B] to-[#A67C00] rounded-2xl p-0.5 h-full">
                <div className="bg-[#1A3A3A] rounded-2xl overflow-hidden h-full flex flex-col">
                  
                  {/* Title Badge */}
                  <div className="relative pt-4 pb-2 flex-shrink-0">
                    <div className="mx-auto w-48 h-10 relative">
                      <svg viewBox="0 0 190 40" className="absolute inset-0 w-full h-full">
                        <defs>
                          <linearGradient id="invBadgeGold" x1="0%" y1="0%" x2="100%" y2="100%">
                            <stop offset="0%" stopColor="#F4E4C1" />
                            <stop offset="50%" stopColor="#D4AF37" />
                            <stop offset="100%" stopColor="#C19A3B" />
                          </linearGradient>
                        </defs>
                        <path d="M 20,5 L 170,5 L 180,20 L 170,35 L 20,35 L 10,20 Z" fill="url(#invBadgeGold)" />
                        <path d="M 5,20 L 15,15 L 25,20 L 15,25 Z" fill="#C19A3B" />
                        <path d="M 185,20 L 175,15 L 165,20 L 175,25 Z" fill="#C19A3B" />
                      </svg>
                      <h2 className="absolute inset-0 flex items-center justify-center text-amber-900 text-xl font-fantasy">
                        Inventaire
                      </h2>
                    </div>
                  </div>

                  {/* Filter Tabs */}
                  <div className="px-4 flex gap-1.5 mb-2 flex-shrink-0 overflow-x-auto scrollbar-hide">
                    {filterTabs.map((tab) => (
                      <button
                        key={tab.id}
                        onClick={() => setActiveFilter(tab.id)}
                        className={`px-4 py-1.5 rounded-t-lg font-semibold text-xs whitespace-nowrap transition-all duration-300 ${
                          activeFilter === tab.id
                            ? 'bg-[#FFFAF0] text-amber-900'
                            : 'bg-gradient-to-br from-amber-800/60 to-amber-900/60 text-amber-200'
                        }`}
                      >
                        {tab.label}
                      </button>
                    ))}
                  </div>

                  {/* Sort/Filter Controls */}
                  <div className="px-4 pb-2 flex gap-2 flex-shrink-0">
                    <button className="flex items-center gap-1 px-3 py-1.5 bg-[#E8D4A0] rounded-lg text-amber-900 text-xs font-semibold">
                      <span>Tri</span>
                      <ChevronDown size={14} />
                    </button>
                    <button className="flex items-center gap-1 px-3 py-1.5 bg-[#E8D4A0] rounded-lg text-amber-900 text-xs font-semibold">
                      <span>Filtre</span>
                      <ChevronDown size={14} />
                    </button>
                  </div>

                  {/* Items Grid - Scrollable */}
                  <div className="px-4 flex-1 overflow-y-auto">
                    <div className="bg-[#FFFAF0] rounded-t-2xl p-3 min-h-full">
                      <div className="grid grid-cols-5 gap-2">
                        {mockItems.map((item) => (
                          <button
                            key={item.id}
                            onClick={() => setSelectedItem(item)}
                            className={`relative aspect-square rounded-lg bg-gradient-to-br ${rarityColors[item.rarity].bg} p-0.5 hover:scale-105 active:scale-95 transition-transform duration-200 ${selectedItem?.id === item.id ? 'ring-2 ring-amber-600 ring-offset-2 ring-offset-[#FFFAF0]' : ''}`}
                          >
                            <div className={`w-full h-full rounded-lg bg-[#F5F5DC] flex items-center justify-center border-2 ${rarityColors[item.rarity].border}`}>
                              <span className="text-xl">{item.icon}</span>
                            </div>
                            
                            {/* Quantity badge */}
                            {item.quantity > 1 && (
                              <div className="absolute -bottom-1 -right-1 w-5 h-5 bg-gray-800 border-2 border-white rounded-full flex items-center justify-center">
                                <span className="text-white text-[10px] font-bold">{item.quantity}</span>
                              </div>
                            )}
                          </button>
                        ))}
                      </div>
                    </div>
                  </div>

                  {/* Item Details Panel */}
                  <AnimatePresence mode="wait">
                    {selectedItem && (
                      <motion.div
                        key={selectedItem.id}
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, y: 20 }}
                        transition={{ duration: 0.3 }}
                        className="px-4 pb-4 pt-2 flex-shrink-0"
                      >
                        <div className="bg-[#FFFAF0] rounded-2xl p-3 border-2 border-amber-600/40">
                          <div className="flex gap-3">
                            {/* Item Icon */}
                            <div className={`w-16 h-16 flex-shrink-0 rounded-lg bg-gradient-to-br ${rarityColors[selectedItem.rarity].bg} p-0.5`}>
                              <div className={`w-full h-full rounded-lg bg-[#F5F5DC] flex items-center justify-center border-2 ${rarityColors[selectedItem.rarity].border}`}>
                                <span className="text-3xl">{selectedItem.icon}</span>
                              </div>
                            </div>

                            {/* Item Info */}
                            <div className="flex-1 min-w-0">
                              <h3 className="text-amber-900 font-semibold mb-0.5 truncate">{selectedItem.name}</h3>
                              <p className={`text-xs font-semibold mb-1 capitalize ${
                                selectedItem.rarity === 'legendary' ? 'text-yellow-600' :
                                selectedItem.rarity === 'epic' ? 'text-purple-600' :
                                selectedItem.rarity === 'rare' ? 'text-blue-600' :
                                selectedItem.rarity === 'uncommon' ? 'text-green-600' :
                                'text-gray-600'
                              }`}>
                                {selectedItem.rarity === 'common' ? 'Commun' :
                                 selectedItem.rarity === 'uncommon' ? 'Peu Commun' :
                                 selectedItem.rarity === 'rare' ? 'Rare' :
                                 selectedItem.rarity === 'epic' ? 'Épique' :
                                 selectedItem.rarity === 'legendary' ? 'Légendaire' :
                                 'Mythique'}
                              </p>
                              <p className="text-amber-800/70 text-[10px] leading-tight">
                                Un objet mystérieux aux propriétés magiques encore inconnues.
                              </p>
                            </div>

                            {/* Actions */}
                            <div className="flex flex-col gap-1.5 flex-shrink-0">
                              <button
                                onClick={() => onEquipItem(selectedItem.id)}
                                className="px-3 py-1.5 bg-gradient-to-br from-yellow-400 to-yellow-600 rounded-lg text-amber-900 text-xs font-semibold hover:from-yellow-300 hover:to-yellow-500 active:scale-95 transition-all duration-200"
                              >
                                Équiper
                              </button>
                              <button className="px-3 py-1.5 bg-gradient-to-br from-red-700 to-red-900 rounded-lg text-red-100 text-xs font-semibold hover:from-red-600 hover:to-red-800 active:scale-95 transition-all duration-200">
                                Jeter
                              </button>
                            </div>
                          </div>
                        </div>
                      </motion.div>
                    )}
                  </AnimatePresence>

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