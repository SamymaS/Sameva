import { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Sparkles, Gem, Wand2 } from 'lucide-react';
import type { UserData, InventoryItem } from '../App';
import { ImageWithFallback } from './figma/ImageWithFallback';
import { RarityBorder, Rarity } from './RarityBorder';

interface InvocationProps {
  userData: UserData;
  onInvoke: (cost: number) => void;
  onReceiveItem: (item: InventoryItem) => void;
}

const possibleRewards: Omit<InventoryItem, 'id' | 'equipped'>[] = [
  { name: 'Robe Mystique', type: 'outfit', rarity: 'rare', icon: '👘' },
  { name: 'Aura Dorée', type: 'aura', rarity: 'epic', icon: '💫' },
  { name: 'Familier Dragon', type: 'companion', rarity: 'legendary', icon: '🐉' },
  { name: 'Chapeau Magique', type: 'outfit', rarity: 'common', icon: '🎩' },
  { name: 'Aura de Feu', type: 'aura', rarity: 'rare', icon: '🔥' },
  { name: 'Chouette Sage', type: 'companion', rarity: 'epic', icon: '🦉' },
];

export function Invocation({ userData, onInvoke, onReceiveItem }: InvocationProps) {
  const [isInvoking, setIsInvoking] = useState(false);
  const [revealedItem, setRevealedItem] = useState<InventoryItem | null>(null);
  const [showReward, setShowReward] = useState(false);

  const invokeCost = 10;

  const handleInvoke = () => {
    if (userData.gems < invokeCost || isInvoking) return;

    setIsInvoking(true);
    onInvoke(invokeCost);

    // Simulate invocation animation
    setTimeout(() => {
      const randomReward = possibleRewards[Math.floor(Math.random() * possibleRewards.length)];
      const newItem: InventoryItem = {
        ...randomReward,
        id: Date.now().toString(),
        equipped: false,
      };

      setRevealedItem(newItem);
      setShowReward(true);
      onReceiveItem(newItem);
      
      setTimeout(() => {
        setIsInvoking(false);
      }, 500);
    }, 3000);
  };

  const closeReward = () => {
    setShowReward(false);
    setRevealedItem(null);
  };

  return (
    <div className="relative h-full flex flex-col overflow-hidden">
      {/* Cosmic Background */}
      <div className="absolute inset-0">
        <ImageWithFallback
          src="https://images.unsplash.com/photo-1710270822096-ccfa274be004?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb3NtaWMlMjBzdGFycyUyMG5lYnVsYSUyMHB1cnBsZXxlbnwxfHx8fDE3NjQ4NTMzNjJ8MA&ixlib=rb-4.1.0&q=80&w=1080"
          alt="Cosmic Background"
          className="w-full h-full object-cover opacity-30"
        />
        <div className="absolute inset-0 bg-gradient-to-b from-[#0F172A]/80 via-[#2D2B55]/70 to-[#0F172A]/90" />
      </div>

      <div className="relative z-10 h-full px-4 pt-6 pb-20 flex flex-col">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="mb-6"
        >
          <div className="flex items-center justify-between mb-4">
            <div>
              <h1 className="text-cream-100 text-2xl tracking-wide mb-1 font-fantasy">Invocation</h1>
              <p className="text-purple-300/60 text-sm">Découvre de nouveaux trésors</p>
            </div>

            <div className="flex items-center gap-2 bg-gradient-to-br from-blue-500/20 to-cyan-500/20 px-4 py-2 rounded-full border border-blue-400/30 shadow-[0_0_20px_rgba(59,130,246,0.3)]">
              <Gem size={18} className="text-cyan-300" />
              <span className="text-cyan-100 font-semibold">{userData.gems}</span>
            </div>
          </div>
        </motion.div>

        {/* Portal Circle - Centre (250px) */}
        <div className="flex-1 flex items-center justify-center">
          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="relative"
          >
            {/* Vortex Portal avec Image */}
            <motion.div
              className="relative w-64 h-64"
              animate={isInvoking ? { rotate: 360 } : { rotate: [0, 360] }}
              transition={
                isInvoking
                  ? { duration: 2, ease: 'linear', repeat: Infinity }
                  : { duration: 20, ease: 'linear', repeat: Infinity }
              }
            >
              {/* Portal rings */}
              <div className="absolute inset-0 rounded-full border-4 border-purple-400/30 blur-sm" />
              <motion.div
                className="absolute inset-4 rounded-full border-4 border-cyan-400/40 blur-sm"
                animate={{ rotate: -360 }}
                transition={{ duration: 15, ease: 'linear', repeat: Infinity }}
              />
              <motion.div
                className="absolute inset-8 rounded-full border-4 border-purple-500/50 blur-sm"
                animate={{ rotate: 360 }}
                transition={{ duration: 10, ease: 'linear', repeat: Infinity }}
              />

              {/* Portal Energy Center */}
              <div className="absolute inset-12 rounded-full overflow-hidden">
                <ImageWithFallback
                  src="https://images.unsplash.com/photo-1752440284390-26d0527bbb9f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxteXN0aWNhbCUyMHBvcnRhbCUyMGVuZXJneXxlbnwxfHx8fDE3NjQ4NTMzNjJ8MA&ixlib=rb-4.1.0&q=80&w=1080"
                  alt="Portal Energy"
                  className="w-full h-full object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-br from-purple-500/60 via-cyan-500/40 to-blue-600/60 mix-blend-overlay" />
                
                {/* Center glow */}
                <motion.div
                  className="absolute inset-0 bg-gradient-radial from-white/40 via-purple-300/30 to-transparent"
                  animate={{
                    scale: isInvoking ? [1, 1.5, 1] : [1, 1.2, 1],
                    opacity: isInvoking ? [0.4, 0.8, 0.4] : [0.3, 0.6, 0.3],
                  }}
                  transition={{
                    duration: isInvoking ? 1 : 3,
                    repeat: Infinity,
                    ease: 'easeInOut',
                  }}
                />
              </div>

              {/* Sparkles flying into portal */}
              {isInvoking && (
                <>
                  {Array.from({ length: 20 }).map((_, i) => {
                    const angle = (i * 360) / 20;
                    const startX = Math.cos((angle * Math.PI) / 180) * 150;
                    const startY = Math.sin((angle * Math.PI) / 180) * 150;
                    
                    return (
                      <motion.div
                        key={i}
                        className="absolute top-1/2 left-1/2 w-2 h-2 bg-white rounded-full"
                        style={{
                          x: startX,
                          y: startY,
                        }}
                        animate={{
                          x: 0,
                          y: 0,
                          opacity: [1, 0],
                          scale: [1, 0],
                        }}
                        transition={{
                          duration: 1.5,
                          repeat: Infinity,
                          delay: i * 0.1,
                          ease: 'easeIn',
                        }}
                      />
                    );
                  })}
                </>
              )}
            </motion.div>

            {/* Outer glow */}
            <motion.div
              className="absolute inset-0 -m-8 rounded-full bg-gradient-radial from-purple-500/20 via-cyan-500/10 to-transparent blur-2xl"
              animate={{
                scale: [1, 1.2, 1],
                opacity: [0.3, 0.6, 0.3],
              }}
              transition={{
                duration: 3,
                repeat: Infinity,
                ease: 'easeInOut',
              }}
            />
          </motion.div>
        </div>

        {/* Buttons - Bas */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.4 }}
          className="flex gap-4"
        >
          {/* Free Invocation (Bleu) */}
          <button
            onClick={handleInvoke}
            disabled={userData.gems < invokeCost || isInvoking}
            className="flex-1 h-14 rounded-full bg-gradient-to-r from-blue-500 to-cyan-500 text-white font-semibold flex items-center justify-center gap-2 shadow-lg shadow-blue-500/30 hover:shadow-blue-500/50 disabled:opacity-50 disabled:cursor-not-allowed active:scale-95 transition-all duration-300"
          >
            <Wand2 size={20} />
            <span>Invoquer ({invokeCost} <Gem size={14} className="inline" />)</span>
          </button>

          {/* Premium Invocation (Doré) */}
          <button
            disabled
            className="flex-1 h-14 rounded-full bg-gradient-to-r from-[#F6E05E] to-[#D69E2E] text-[#2D2B55] font-semibold flex items-center justify-center gap-2 shadow-lg shadow-yellow-500/30 opacity-50 cursor-not-allowed"
          >
            <Sparkles size={20} />
            <span>Premium</span>
          </button>
        </motion.div>
      </div>

      {/* Reward Modal - Loot Screen selon GDD */}
      <AnimatePresence>
        {showReward && revealedItem && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="absolute inset-0 z-50 flex items-center justify-center"
            onClick={closeReward}
          >
            {/* Rayons de lumière tournants (Sunburst) */}
            <div className="absolute inset-0 overflow-hidden">
              <motion.div
                className="absolute inset-0"
                animate={{ rotate: 360 }}
                transition={{ duration: 20, ease: 'linear', repeat: Infinity }}
                style={{
                  background: `conic-gradient(
                    from 0deg,
                    transparent 0deg,
                    ${revealedItem.rarity === 'legendary' ? 'rgba(236, 201, 75, 0.3)' : 'rgba(159, 122, 234, 0.3)'} 30deg,
                    transparent 60deg,
                    transparent 120deg,
                    ${revealedItem.rarity === 'legendary' ? 'rgba(236, 201, 75, 0.3)' : 'rgba(159, 122, 234, 0.3)'} 150deg,
                    transparent 180deg,
                    transparent 240deg,
                    ${revealedItem.rarity === 'legendary' ? 'rgba(236, 201, 75, 0.3)' : 'rgba(159, 122, 234, 0.3)'} 270deg,
                    transparent 300deg,
                    transparent 360deg
                  )`,
                }}
              />
            </div>

            {/* Dark overlay */}
            <div className="absolute inset-0 bg-black/70 backdrop-blur-sm" />

            {/* Item Card */}
            <motion.div
              initial={{ scale: 0.5, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.5, opacity: 0 }}
              transition={{ type: 'spring', damping: 15 }}
              onClick={(e) => e.stopPropagation()}
              className="relative z-10"
            >
              <RarityBorder
                rarity={revealedItem.rarity as Rarity}
                className="bg-[#1A202C] rounded-3xl p-8"
                withGlow
              >
                {/* Objet flottant */}
                <motion.div
                  className="text-center mb-6"
                  animate={{ y: [0, -10, 0] }}
                  transition={{
                    duration: 2,
                    repeat: Infinity,
                    ease: 'easeInOut',
                  }}
                >
                  <div className="text-9xl mb-4">{revealedItem.icon}</div>
                  
                  {/* Nom */}
                  <h2 className="text-white text-3xl mb-3 font-fantasy">
                    {revealedItem.name}
                  </h2>
                  
                  {/* Rareté Badge */}
                  <div className="inline-block px-6 py-2 rounded-full text-sm font-bold uppercase tracking-[4px]"
                    style={{
                      color: revealedItem.rarity === 'legendary' ? '#ECC94B' : 
                             revealedItem.rarity === 'epic' ? '#9F7AEA' : 
                             revealedItem.rarity === 'rare' ? '#4299E1' : '#CBD5E0',
                      backgroundColor: revealedItem.rarity === 'legendary' ? 'rgba(236, 201, 75, 0.2)' : 
                                      revealedItem.rarity === 'epic' ? 'rgba(159, 122, 234, 0.2)' : 
                                      revealedItem.rarity === 'rare' ? 'rgba(66, 153, 225, 0.2)' : 'rgba(203, 213, 224, 0.2)',
                      border: `2px solid ${revealedItem.rarity === 'legendary' ? '#ECC94B' : 
                                          revealedItem.rarity === 'epic' ? '#9F7AEA' : 
                                          revealedItem.rarity === 'rare' ? '#4299E1' : '#CBD5E0'}`,
                    }}
                  >
                    {revealedItem.rarity}
                  </div>
                </motion.div>

                {/* Bouton Continuer (Ghost button discret) */}
                <button
                  onClick={closeReward}
                  className="w-full h-12 rounded-full border-2 border-white/20 text-white/60 font-semibold hover:bg-white/5 hover:text-white/80 active:scale-95 transition-all duration-200"
                >
                  Continuer
                </button>
              </RarityBorder>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}