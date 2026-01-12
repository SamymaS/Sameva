import { motion } from 'motion/react';
import { Plus, Zap, Coins, Gem, ChevronRight } from 'lucide-react';
import type { UserData, Page, Quest } from '../App';
import { MotivationalQuote } from './MotivationalQuote';
import { MagicParticles } from './MagicParticles';
import { ImageWithFallback } from './figma/ImageWithFallback';

interface SanctuaryProps {
  userData: UserData;
  onNavigate: (page: Page) => void;
  onCompleteQuest: (questId: string) => void;
  activeQuests: Quest[];
}

export function Sanctuary({ userData, onNavigate, onCompleteQuest, activeQuests }: SanctuaryProps) {
  const xpPercentage = (userData.xp / userData.maxXp) * 100;

  return (
    <div className="relative h-full flex flex-col pt-4 pb-24">
      {/* Background particles "Poussière de Fée" */}
      <MagicParticles count={20} color="rgba(128, 90, 213, 0.3)" size={2} />
      
      {/* Header - Top Bar (80px) */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="px-4 mb-3"
      >
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-3">
            {/* Avatar miniature */}
            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-purple-300/30 to-blue-300/30 border-2 border-purple-300/50 flex items-center justify-center">
              <span className="text-xl">🧙‍♀️</span>
            </div>
            <div>
              <h1 className="text-white font-semibold">
                {userData.name}
              </h1>
              <p className="text-purple-300/60 text-xs">Niveau {userData.level}</p>
            </div>
          </div>
          
          <div className="flex gap-2">
            <div className="flex items-center gap-1 bg-gradient-to-br from-yellow-500/20 to-orange-500/20 px-2.5 py-1 rounded-full border border-yellow-500/30 shadow-[0_0_15px_rgba(251,191,36,0.2)]">
              <Coins size={14} className="text-yellow-300" />
              <span className="text-yellow-100 text-xs font-semibold">{userData.gold}</span>
            </div>
            <div className="flex items-center gap-1 bg-gradient-to-br from-blue-500/20 to-cyan-500/20 px-2.5 py-1 rounded-full border border-blue-400/30 shadow-[0_0_15px_rgba(59,130,246,0.2)]">
              <Gem size={14} className="text-cyan-300" />
              <span className="text-cyan-100 text-xs font-semibold">{userData.gems}</span>
            </div>
          </div>
        </div>

        {/* XP Bar - Gradient Violet */}
        <div className="relative">
          <div className="flex items-center justify-between mb-1.5">
            <span className="text-purple-200 text-xs">XP</span>
            <span className="text-purple-300/60 text-xs">{userData.xp} / {userData.maxXp}</span>
          </div>
          <div className="relative h-2 bg-purple-950/50 rounded-full overflow-hidden border border-purple-500/20">
            <motion.div
              className="absolute inset-y-0 left-0 bg-gradient-to-r from-[#805AD5] to-[#B794F4] rounded-full shadow-[0_0_15px_rgba(128,90,213,0.6)]"
              initial={{ width: 0 }}
              animate={{ width: `${xpPercentage}%` }}
              transition={{ duration: 1, ease: 'easeOut', delay: 0.3 }}
            />
          </div>
        </div>
      </motion.div>

      {/* Avatar & Sanctuary Scene - Main Zone (45% height) */}
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.6, delay: 0.2 }}
        className="relative mx-4 mb-4 flex-shrink-0"
        style={{ height: '35%' }}
      >
        <div className="relative w-full h-full rounded-3xl overflow-hidden border border-purple-400/20 shadow-[0_8px_40px_rgba(139,92,246,0.3)]">
          {/* Background sanctuary with image */}
          <div className="absolute inset-0">
            {/* Background image */}
            <ImageWithFallback
              src="https://images.unsplash.com/photo-1642677674839-b9e5b94ea88c?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhbmNpZW50JTIwcnVpbnMlMjBtb29ubGlnaHR8ZW58MXx8fHwxNzY0ODUzMzYzfDA&ixlib=rb-4.1.0&q=80&w=1080"
              alt="Sanctuary Background"
              className="w-full h-full object-cover opacity-40"
            />
            
            {/* Overlay gradients */}
            <div className="absolute inset-0 bg-gradient-to-b from-indigo-950/80 via-purple-900/60 to-violet-950/80" />
            
            {/* Starry background */}
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
                    scale: [0.8, 1.2, 0.8],
                  }}
                  transition={{
                    duration: Math.random() * 3 + 2,
                    repeat: Infinity,
                    delay: Math.random() * 2,
                  }}
                />
              ))}
            </div>

            {/* Spot lumineux du haut (Radial Gradient) */}
            <div 
              className="absolute top-0 left-1/2 -translate-x-1/2 w-full h-1/2"
              style={{
                background: 'radial-gradient(ellipse at top, rgba(255, 255, 255, 0.2) 0%, transparent 60%)',
              }}
            />
            
            {/* Light rays */}
            <div className="absolute top-0 left-1/4 w-1 h-full bg-gradient-to-b from-blue-300/20 via-purple-300/10 to-transparent blur-sm" />
            <div className="absolute top-0 right-1/3 w-1 h-full bg-gradient-to-b from-purple-300/20 via-blue-300/10 to-transparent blur-sm" />
          </div>

          {/* Avatar - Centré, pieds à 15% du bas */}
          <div className="absolute inset-0 flex items-end justify-center" style={{ paddingBottom: '15%' }}>
            <motion.div
              className="relative"
              animate={{
                y: [0, -6, 0],
              }}
              transition={{
                duration: 4,
                repeat: Infinity,
                ease: 'easeInOut',
              }}
            >
              {/* Aura effect */}
              <motion.div
                className="absolute inset-0 -m-8 bg-gradient-radial from-purple-400/40 via-blue-400/20 to-transparent rounded-full blur-2xl"
                animate={{
                  scale: [1, 1.15, 1],
                  opacity: [0.4, 0.6, 0.4],
                }}
                transition={{
                  duration: 3,
                  repeat: Infinity,
                  ease: 'easeInOut',
                }}
              />
              
              {/* Avatar placeholder */}
              <div className="relative w-24 h-24 bg-gradient-to-br from-purple-300/30 to-blue-300/30 rounded-full border-2 border-purple-300/50 shadow-[0_0_40px_rgba(216,180,254,0.6)] flex items-center justify-center backdrop-blur-sm">
                <span className="text-5xl">🧙‍♀️</span>
              </div>

              {/* Ombre elliptique sous les pieds (40% opacity) */}
              <div 
                className="absolute -bottom-2 left-1/2 -translate-x-1/2 w-20 h-4 bg-black/40 rounded-full blur-md"
              />

              {/* Companion */}
              <motion.div
                className="absolute -right-12 top-4 text-2xl"
                animate={{
                  y: [0, -4, 0],
                  rotate: [-5, 5, -5],
                }}
                transition={{
                  duration: 3,
                  repeat: Infinity,
                  ease: 'easeInOut',
                  delay: 0.5,
                }}
              >
                <span className="drop-shadow-[0_0_10px_rgba(251,191,36,0.6)]">🦊</span>
              </motion.div>
            </motion.div>
          </div>

          {/* Customization button */}
          <button
            onClick={() => onNavigate('customization')}
            className="absolute top-3 right-3 p-2 bg-purple-500/20 backdrop-blur-md rounded-full border border-purple-300/30 hover:bg-purple-500/30 active:scale-95 transition-all duration-300 shadow-[0_0_20px_rgba(168,85,247,0.3)] hover:shadow-[0_0_30px_rgba(168,85,247,0.5)]"
          >
            <Zap size={18} className="text-purple-200" />
          </button>
        </div>
      </motion.div>

      {/* Motivational Quote */}
      <div className="px-4">
        <MotivationalQuote />
      </div>

      {/* Active Quests Preview - Above FAB */}
      {activeQuests.length > 0 && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.5 }}
          className="flex-1 min-h-0 px-4 overflow-hidden"
        >
          <div className="flex items-center justify-between mb-2">
            <h2 className="text-purple-100 tracking-wide text-sm font-semibold">Quêtes en cours</h2>
            <button
              onClick={() => onNavigate('quests')}
              className="text-purple-300/60 text-xs hover:text-purple-300 transition-colors duration-300"
            >
              Voir tout
            </button>
          </div>

          {/* Carrousel horizontal - Style Parchemin */}
          <div className="flex gap-4 overflow-x-auto pb-2 hide-scrollbar">
            {activeQuests.map((quest, index) => (
              <motion.div
                key={quest.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.4, delay: 0.6 + index * 0.1 }}
                className="flex-shrink-0 w-[280px] h-[140px] p-4 bg-[#FFFAF0] rounded-xl border border-[#D69E2E] shadow-lg relative overflow-hidden"
                style={{
                  backgroundImage: 'linear-gradient(to bottom, #FFFAF0 0%, #FAF5E6 100%)',
                }}
              >
                <div className="flex flex-col h-full">
                  <div className="flex items-start justify-between mb-2">
                    <div className="flex-1 min-w-0">
                      <h3 className="text-[#2D2B55] font-semibold text-sm truncate mb-1">{quest.title}</h3>
                      <p className="text-[#4A5568] text-xs line-clamp-2">{quest.description}</p>
                    </div>
                  </div>
                  
                  <div className="mt-auto">
                    {/* Progress bar */}
                    <div className="h-1.5 bg-purple-200/50 rounded-full overflow-hidden mb-2">
                      <motion.div
                        className="h-full bg-gradient-to-r from-purple-400 to-blue-400 rounded-full"
                        initial={{ width: 0 }}
                        animate={{ width: `${quest.progress || 0}%` }}
                        transition={{ duration: 0.8, delay: 0.7 + index * 0.1 }}
                      />
                    </div>
                    
                    {/* Récompense Badge */}
                    <div className="flex items-center justify-between">
                      <span className="text-xs text-[#2D2B55]/60">{quest.progress}% complété</span>
                      <div className="px-2 py-1 bg-gradient-to-r from-yellow-400/20 to-orange-400/20 rounded-full border border-yellow-500/30">
                        <span className="text-xs font-semibold text-[#D69E2E]">+{quest.rewards.xp} XP</span>
                      </div>
                    </div>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </motion.div>
      )}

      {/* FAB (Floating Action Button) - Centré en bas, chevauche tout */}
      <motion.button
        initial={{ opacity: 0, scale: 0 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.5, delay: 0.8 }}
        onClick={() => onNavigate('quest-creation')}
        className="absolute bottom-28 left-1/2 -translate-x-1/2 w-16 h-16 rounded-full bg-gradient-to-br from-[#F6E05E] to-[#D69E2E] shadow-[0_8px_30px_rgba(246,224,94,0.6)] flex items-center justify-center z-50 active:scale-95 transition-all duration-300"
        whileHover={{ scale: 1.1 }}
        animate={{
          boxShadow: [
            '0 8px 30px rgba(246, 224, 94, 0.6)',
            '0 8px 40px rgba(246, 224, 94, 0.8)',
            '0 8px 30px rgba(246, 224, 94, 0.6)',
          ],
        }}
        transition={{
          duration: 2,
          repeat: Infinity,
          ease: 'easeInOut',
        }}
      >
        <Plus size={32} className="text-[#2D2B55]" strokeWidth={3} />
      </motion.button>

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