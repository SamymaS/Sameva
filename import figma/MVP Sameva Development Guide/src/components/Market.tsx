import { useState } from 'react';
import { motion } from 'motion/react';
import { ShoppingBag, Coins, Clock, Sparkles, RefreshCw } from 'lucide-react';
import type { UserData } from '../App';

interface MarketProps {
  userData: UserData;
  onPurchase: (cost: number) => void;
}

interface MarketItem {
  id: string;
  name: string;
  icon: string;
  price: number;
  rarity: 'common' | 'rare' | 'epic' | 'legendary';
  type: string;
  description: string;
}

const rarityColors = {
  common: { bg: 'from-gray-500/20 to-gray-600/20', border: 'gray-400/30', text: 'gray-300' },
  rare: { bg: 'from-blue-500/20 to-cyan-500/20', border: 'blue-400/40', text: 'blue-300' },
  epic: { bg: 'from-purple-500/20 to-pink-500/20', border: 'purple-400/40', text: 'purple-300' },
  legendary: { bg: 'from-yellow-500/20 to-orange-500/20', border: 'yellow-400/40', text: 'yellow-300' },
};

export function Market({ userData, onPurchase }: MarketProps) {
  const [timeLeft, setTimeLeft] = useState('23:45:12');
  const [purchasedItems, setPurchasedItems] = useState<Set<string>>(new Set());

  const dailyItems: MarketItem[] = [
    {
      id: '1',
      name: 'Robe Céleste',
      icon: '👘',
      price: 500,
      rarity: 'epic',
      type: 'Tenue',
      description: 'Une robe tissée de lumière lunaire',
    },
    {
      id: '2',
      name: 'Aura de Sagesse',
      icon: '✨',
      price: 300,
      rarity: 'rare',
      type: 'Aura',
      description: 'Émane une énergie apaisante',
    },
    {
      id: '3',
      name: 'Potion de Vitalité',
      icon: '🧪',
      price: 100,
      rarity: 'common',
      type: 'Consommable',
      description: 'Restaure ton énergie',
    },
    {
      id: '4',
      name: 'Couronne Stellaire',
      icon: '👑',
      price: 1200,
      rarity: 'legendary',
      type: 'Tenue',
      description: 'Forgée dans les étoiles anciennes',
    },
  ];

  const handlePurchase = (item: MarketItem) => {
    if (userData.gold >= item.price && !purchasedItems.has(item.id)) {
      onPurchase(item.price);
      setPurchasedItems(prev => new Set(prev).add(item.id));
    }
  };

  return (
    <div className="h-full flex flex-col px-4 pt-6 pb-20">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="mb-6"
      >
        <div className="flex items-center justify-between mb-4">
          <div>
            <h1 className="text-cream-100 text-2xl tracking-wide mb-1">Marché Mystique</h1>
            <p className="text-purple-300/60 text-sm">Trésors quotidiens</p>
          </div>

          <div className="flex items-center gap-2 bg-gradient-to-br from-yellow-500/20 to-orange-500/20 px-4 py-2 rounded-full border border-yellow-500/30">
            <Coins size={18} className="text-yellow-300" />
            <span className="text-yellow-100">{userData.gold}</span>
          </div>
        </div>

        {/* Timer */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.5, delay: 0.1 }}
          className="flex items-center justify-between p-4 bg-gradient-to-br from-purple-900/30 to-blue-900/30 rounded-2xl border border-purple-400/20"
        >
          <div className="flex items-center gap-2">
            <div className="w-10 h-10 rounded-full bg-purple-500/20 flex items-center justify-center border border-purple-400/30">
              <Clock size={20} className="text-purple-300" />
            </div>
            <div>
              <p className="text-purple-100 text-sm">Renouvellement dans</p>
              <p className="text-purple-300/60 text-xs">{timeLeft}</p>
            </div>
          </div>

          <button className="p-2 rounded-full bg-purple-500/20 border border-purple-400/30 hover:bg-purple-500/30 transition-all duration-300">
            <RefreshCw size={18} className="text-purple-200" />
          </button>
        </motion.div>
      </motion.div>

      {/* Items Grid */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.5, delay: 0.2 }}
        className="space-y-4"
      >
        {dailyItems.map((item, index) => {
          const rarity = rarityColors[item.rarity];
          const isPurchased = purchasedItems.has(item.id);
          const canAfford = userData.gold >= item.price;

          return (
            <motion.div
              key={item.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, delay: 0.3 + index * 0.1 }}
              className={`relative p-4 rounded-2xl border transition-all duration-300 bg-gradient-to-br ${rarity.bg} border-${rarity.border} overflow-hidden`}
            >
              {/* Background glow */}
              <div className={`absolute inset-0 bg-gradient-to-br ${rarity.bg} opacity-0 hover:opacity-100 transition-opacity duration-300 blur-xl -z-10`} />

              <div className="flex items-start gap-4">
                {/* Item Icon */}
                <div className={`flex-shrink-0 w-20 h-20 rounded-xl flex items-center justify-center border bg-gradient-to-br ${rarity.bg} border-${rarity.border} shadow-[0_0_20px_rgba(168,85,247,0.3)]`}>
                  <span className="text-5xl">{item.icon}</span>
                </div>

                {/* Item Info */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2 mb-1">
                    <h3 className="text-purple-100">{item.name}</h3>
                    <span className={`text-${rarity.text} text-xs uppercase tracking-wider`}>
                      {item.rarity}
                    </span>
                  </div>
                  
                  <p className="text-purple-300/60 text-sm mb-2">{item.type}</p>
                  <p className="text-purple-300/50 text-sm mb-3">{item.description}</p>

                  {/* Price and Action */}
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <Coins size={18} className="text-yellow-300" />
                      <span className="text-yellow-100">{item.price}</span>
                    </div>

                    <button
                      onClick={() => handlePurchase(item)}
                      disabled={isPurchased || !canAfford}
                      className={`px-4 py-2 rounded-xl flex items-center gap-2 transition-all duration-300 ${
                        isPurchased
                          ? 'bg-green-500/20 border border-green-400/40 text-green-300 cursor-default'
                          : canAfford
                          ? 'bg-gradient-to-r from-purple-500 to-blue-500 shadow-[0_0_20px_rgba(168,85,247,0.4)] hover:shadow-[0_0_30px_rgba(168,85,247,0.6)] text-white'
                          : 'bg-purple-950/30 border border-purple-500/20 text-purple-400/40 cursor-not-allowed'
                      }`}
                    >
                      {isPurchased ? (
                        <>
                          <Sparkles size={16} />
                          <span className="text-sm">Acheté</span>
                        </>
                      ) : (
                        <>
                          <ShoppingBag size={16} />
                          <span className="text-sm">Acheter</span>
                        </>
                      )}
                    </button>
                  </div>
                </div>
              </div>

              {/* Purchased overlay */}
              {isPurchased && (
                <motion.div
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  className="absolute inset-0 bg-green-500/10 backdrop-blur-[1px] pointer-events-none"
                />
              )}

              {/* Shimmer effect */}
              {!isPurchased && canAfford && (
                <motion.div
                  className="absolute inset-0 bg-gradient-to-r from-transparent via-white/5 to-transparent pointer-events-none"
                  animate={{
                    x: ['-100%', '200%'],
                  }}
                  transition={{
                    duration: 3,
                    repeat: Infinity,
                    repeatDelay: 2,
                    ease: 'easeInOut',
                  }}
                />
              )}
            </motion.div>
          );
        })}
      </motion.div>

      {/* Info Card */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.7 }}
        className="mt-6 p-4 bg-gradient-to-br from-purple-900/20 to-blue-900/20 rounded-2xl border border-purple-400/20"
      >
        <div className="flex items-start gap-3">
          <div className="w-8 h-8 rounded-full bg-purple-500/20 flex items-center justify-center border border-purple-400/30 flex-shrink-0">
            <Sparkles size={16} className="text-purple-300" />
          </div>
          <div>
            <p className="text-purple-200 text-sm mb-1">Marché quotidien</p>
            <p className="text-purple-300/50 text-xs">
              Les objets du marché changent chaque jour. Reviens régulièrement pour découvrir de nouveaux trésors mystiques.
            </p>
          </div>
        </div>
      </motion.div>
    </div>
  );
}
