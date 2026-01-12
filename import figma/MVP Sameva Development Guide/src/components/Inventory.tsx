import { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Package, Sparkles, Shirt, Wand2, Home, Check } from 'lucide-react';
import type { InventoryItem } from '../App';
import { RarityBorder, Rarity } from './RarityBorder';

interface InventoryProps {
  items: InventoryItem[];
  onEquip: (itemId: string) => void;
}

type ItemFilter = 'all' | 'outfit' | 'aura' | 'decoration' | 'companion' | 'consumable';

// Nouveau mapping selon le GDD
const rarityStyles: Record<string, { color: string; glow: string }> = {
  common: { color: '#CBD5E0', glow: 'rgba(203, 213, 224, 0.3)' },
  uncommon: { color: '#68D391', glow: 'rgba(104, 211, 145, 0.3)' },
  rare: { color: '#4299E1', glow: 'rgba(66, 153, 225, 0.3)' },
  epic: { color: '#9F7AEA', glow: 'rgba(159, 122, 234, 0.4)' },
  legendary: { color: '#ECC94B', glow: 'rgba(236, 201, 75, 0.5)' },
  mythic: { color: '#FC8181', glow: 'rgba(252, 129, 129, 0.6)' },
};

const filterOptions = [
  { id: 'all' as ItemFilter, label: 'Tous', icon: Package },
  { id: 'outfit' as ItemFilter, label: 'Tenues', icon: Shirt },
  { id: 'aura' as ItemFilter, label: 'Auras', icon: Sparkles },
  { id: 'decoration' as ItemFilter, label: 'Décors', icon: Home },
  { id: 'companion' as ItemFilter, label: 'Familiers', icon: Wand2 },
];

export function Inventory({ items, onEquip }: InventoryProps) {
  const [filter, setFilter] = useState<ItemFilter>('all');
  const [selectedItem, setSelectedItem] = useState<InventoryItem | null>(null);

  const filteredItems = items.filter(item => filter === 'all' || item.type === filter);

  return (
    <div className="h-full flex flex-col px-4 pt-6 pb-24">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="mb-4"
      >
        <h1 className="text-cream-100 text-2xl tracking-wide mb-1 font-fantasy">Inventaire</h1>
        <p className="text-purple-300/60 text-sm">Gérer tes trésors</p>
      </motion.div>

      {/* Filters - Scroll Horizontal */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.1 }}
        className="mb-4 overflow-x-auto hide-scrollbar"
      >
        <div className="flex gap-2 pb-2">
          {filterOptions.map((option) => {
            const Icon = option.icon;
            const isActive = filter === option.id;
            return (
              <button
                key={option.id}
                onClick={() => setFilter(option.id)}
                className={`flex items-center gap-2 px-4 py-2 rounded-full whitespace-nowrap transition-all duration-300 ${
                  isActive
                    ? 'bg-gradient-to-r from-[#4FD1C5] to-[#38B2AC] text-white shadow-lg shadow-cyan-500/30'
                    : 'bg-transparent border border-white/30 text-white/70 hover:border-white/50'
                }`}
              >
                <Icon size={16} />
                <span className="text-sm font-semibold">{option.label}</span>
              </button>
            );
          })}
        </div>
      </motion.div>

      {/* Grid - 3 colonnes, Gap 12px */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.5, delay: 0.2 }}
        className="flex-1 overflow-y-auto"
      >
        <div className="grid grid-cols-3 gap-3 pb-4">
          {filteredItems.map((item, index) => {
            const rarity = item.rarity as Rarity;
            const rarityStyle = rarityStyles[rarity];
            
            return (
              <motion.div
                key={item.id}
                initial={{ opacity: 0, scale: 0.8 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ duration: 0.3, delay: index * 0.05 }}
              >
                <RarityBorder
                  rarity={rarity}
                  className="relative aspect-square rounded-xl overflow-hidden cursor-pointer group"
                  withGlow={rarity === 'epic' || rarity === 'legendary' || rarity === 'mythic'}
                >
                  <button
                    onClick={() => setSelectedItem(item)}
                    className="w-full h-full bg-[#1A202C]/80 backdrop-blur-sm flex flex-col items-center justify-center p-2 hover:bg-[#1A202C] transition-all duration-300"
                  >
                    {/* Item Icon */}
                    <span className="text-4xl mb-1">{item.icon}</span>
                    
                    {/* Item Name */}
                    <p className="text-white text-xs text-center truncate w-full px-1">
                      {item.name}
                    </p>
                    
                    {/* Equipped indicator */}
                    {item.equipped && (
                      <div className="absolute top-1 right-1 w-5 h-5 rounded-full bg-gradient-to-br from-green-400 to-green-600 flex items-center justify-center shadow-lg">
                        <Check size={12} className="text-white" strokeWidth={3} />
                      </div>
                    )}
                    
                    {/* Rarity indicator badge (si quantité pour consumables) */}
                    {item.type === 'consumable' && (
                      <div 
                        className="absolute bottom-1 right-1 px-1.5 py-0.5 rounded-full text-white text-xs font-semibold"
                        style={{ 
                          backgroundColor: 'rgba(0, 0, 0, 0.7)',
                          border: `1px solid ${rarityStyle.color}`
                        }}
                      >
                        x1
                      </div>
                    )}
                  </button>
                </RarityBorder>
              </motion.div>
            );
          })}
        </div>
      </motion.div>

      {/* Item Detail Modal */}
      <AnimatePresence>
        {selectedItem && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 flex items-center justify-center p-6"
            onClick={() => setSelectedItem(null)}
          >
            <motion.div
              initial={{ scale: 0.8, y: 50 }}
              animate={{ scale: 1, y: 0 }}
              exit={{ scale: 0.8, y: 50 }}
              transition={{ type: 'spring', damping: 20 }}
              onClick={(e) => e.stopPropagation()}
              className="w-full max-w-sm"
            >
              <RarityBorder
                rarity={selectedItem.rarity as Rarity}
                className="bg-[#1A202C] rounded-3xl p-6"
                withGlow
              >
                {/* Item Display */}
                <div className="text-center mb-6">
                  <div className="text-8xl mb-4">{selectedItem.icon}</div>
                  <h2 className="text-white text-2xl font-fantasy mb-2">{selectedItem.name}</h2>
                  <div className="inline-block px-4 py-1 rounded-full text-sm font-semibold uppercase tracking-wider"
                    style={{
                      color: rarityStyles[selectedItem.rarity].color,
                      backgroundColor: rarityStyles[selectedItem.rarity].glow,
                      border: `1px solid ${rarityStyles[selectedItem.rarity].color}`,
                    }}
                  >
                    {selectedItem.rarity}
                  </div>
                </div>

                {/* Type */}
                <div className="mb-6 text-center">
                  <p className="text-purple-200/60 text-sm">
                    Type: <span className="text-purple-200 capitalize">{selectedItem.type}</span>
                  </p>
                </div>

                {/* Actions */}
                <div className="flex gap-3">
                  <button
                    onClick={() => setSelectedItem(null)}
                    className="flex-1 h-12 rounded-full border-2 border-white/20 text-white font-semibold hover:bg-white/5 active:scale-95 transition-all duration-200"
                  >
                    Fermer
                  </button>
                  <button
                    onClick={() => {
                      onEquip(selectedItem.id);
                      setSelectedItem(null);
                    }}
                    className="flex-1 h-12 rounded-full bg-gradient-to-r from-[#4FD1C5] to-[#38B2AC] text-white font-semibold shadow-lg shadow-cyan-500/30 hover:shadow-cyan-500/50 active:scale-95 transition-all duration-200"
                  >
                    {selectedItem.equipped ? 'Déséquiper' : 'Équiper'}
                  </button>
                </div>
              </RarityBorder>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      <style jsx>{`
        .hide-scrollbar {
          scrollbar-width: none;
          -ms-overflow-style: none;
        }
        .hide-scrollbar::-webkit-scrollbar {
          display: none;
        }
      `}</style>
    </div>
  );
}