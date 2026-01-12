import { motion } from 'motion/react';
import { Plus } from 'lucide-react';
import type { UserData, Page, Quest } from '../App';
import { HeaderBar } from './HeaderBar';
import { ImageWithFallback } from './figma/ImageWithFallback';

interface SanctuaryV2Props {
  userData: UserData;
  activeQuests: Quest[];
  onNavigate: (page: Page) => void;
}

export function SanctuaryV2({ userData, activeQuests, onNavigate }: SanctuaryV2Props) {
  // Mock quick actions for carousel
  const quickActions = [
    { id: 1, icon: '📖', title: 'Lire 10 pages', color: 'from-red-800/60 to-red-900/60', borderColor: 'border-red-700' },
    { id: 2, icon: '⚔️', title: 'Faire du sport', color: 'from-gray-600/60 to-gray-700/60', borderColor: 'border-gray-600' },
    { id: 3, icon: '🧪', title: 'Méditer 15min', color: 'from-pink-700/60 to-purple-800/60', borderColor: 'border-purple-700' },
  ];

  return (
    <div className="relative w-full h-full overflow-hidden">
      {/* Background - Mystical Forest */}
      <div className="absolute inset-0">
        <ImageWithFallback 
          src="https://images.unsplash.com/photo-1603531763662-109ff15864c0?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxteXN0aWNhbCUyMGZvcmVzdCUyMG5pZ2h0JTIwcHVycGxlfGVufDF8fHx8MTc2NDkyOTg2MHww&ixlib=rb-4.1.0&q=80&w=1080"
          alt="Mystical Forest" 
          className="w-full h-full object-cover"
        />
        {/* Gradient overlays for depth */}
        <div className="absolute inset-0 bg-gradient-to-b from-purple-950/40 via-transparent to-black/60" />
        <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-transparent" />
      </div>

      {/* Ornate golden side frames */}
      <div className="absolute inset-y-0 left-0 w-6 pointer-events-none z-0">
        <svg viewBox="0 0 32 800" className="w-full h-full" preserveAspectRatio="none">
          <defs>
            <linearGradient id="sideGold" x1="0%" y1="0%" x2="100%" y2="0%">
              <stop offset="0%" stopColor="#C19A3B" />
              <stop offset="50%" stopColor="#F4E4C1" />
              <stop offset="100%" stopColor="#D4AF37" />
            </linearGradient>
          </defs>
          <path d="M 0,0 L 32,0 L 32,800 L 0,800 Q 10,400 0,0" fill="url(#sideGold)" opacity="0.8" />
          <path d="M 5,50 L 20,50 L 20,750 L 5,750 Q 12,400 5,50" fill="#3D2817" opacity="0.5" />
        </svg>
      </div>
      
      <div className="absolute inset-y-0 right-0 w-6 pointer-events-none z-0">
        <svg viewBox="0 0 32 800" className="w-full h-full" preserveAspectRatio="none">
          <defs>
            <linearGradient id="sideGoldR" x1="100%" y1="0%" x2="0%" y2="0%">
              <stop offset="0%" stopColor="#C19A3B" />
              <stop offset="50%" stopColor="#F4E4C1" />
              <stop offset="100%" stopColor="#D4AF37" />
            </linearGradient>
          </defs>
          <path d="M 32,0 L 0,0 L 0,800 L 32,800 Q 22,400 32,0" fill="url(#sideGoldR)" opacity="0.8" />
          <path d="M 27,50 L 12,50 L 12,750 L 27,750 Q 20,400 27,50" fill="#3D2817" opacity="0.5" />
        </svg>
      </div>

      {/* Header */}
      <HeaderBar userData={userData} onNavigate={onNavigate} />

      {/* Main Content */}
      <div className="relative z-10 h-full flex flex-col pt-16 pb-24">
        {/* Central Scene - Character + Familiar with magical effects */}
        <div className="flex-1 flex items-center justify-center px-8 relative">
          
          {/* Magic Circle on ground */}
          <motion.div
            className="absolute bottom-32 left-1/2 -translate-x-1/2 w-80 h-80"
            animate={{ rotate: 360 }}
            transition={{ duration: 30, repeat: Infinity, ease: "linear" }}
          >
            <svg viewBox="0 0 300 300" className="w-full h-full opacity-30">
              <defs>
                <linearGradient id="circleGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                  <stop offset="0%" stopColor="#4FD1C5" />
                  <stop offset="50%" stopColor="#805AD5" />
                  <stop offset="100%" stopColor="#F6E05E" />
                </linearGradient>
              </defs>
              {/* Outer circle */}
              <circle cx="150" cy="150" r="145" fill="none" stroke="url(#circleGradient)" strokeWidth="2" opacity="0.6" />
              <circle cx="150" cy="150" r="130" fill="none" stroke="url(#circleGradient)" strokeWidth="1" opacity="0.4" />
              
              {/* Pentagram */}
              <path d="M 150,20 L 175,120 L 270,120 L 190,180 L 220,270 L 150,215 L 80,270 L 110,180 L 30,120 L 125,120 Z" 
                    fill="none" stroke="url(#circleGradient)" strokeWidth="2" opacity="0.5" />
              
              {/* Runes around */}
              {Array.from({ length: 12 }).map((_, i) => {
                const angle = (i * 30) * Math.PI / 180;
                const x = 150 + Math.cos(angle) * 120;
                const y = 150 + Math.sin(angle) * 120;
                return (
                  <text key={i} x={x} y={y} fontSize="16" fill="#4FD1C5" opacity="0.6" textAnchor="middle">✦</text>
                );
              })}
            </svg>
          </motion.div>

          {/* Character container with glow */}
          <div className="relative z-10">
            {/* Outer magical aura */}
            <motion.div
              className="absolute inset-0 -m-16 rounded-full bg-gradient-to-br from-cyan-400/20 via-purple-500/20 to-yellow-400/20 blur-3xl"
              animate={{
                scale: [1, 1.2, 1],
                opacity: [0.3, 0.6, 0.3],
              }}
              transition={{
                duration: 4,
                repeat: Infinity,
                ease: "easeInOut",
              }}
            />

            {/* Character */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 1, delay: 0.3 }}
              className="relative"
            >
              {/* Main character - Using emoji for now, would be custom sprite */}
              <div className="relative z-20">
                <motion.div
                  animate={{ y: [0, -10, 0] }}
                  transition={{ duration: 3, repeat: Infinity, ease: "easeInOut" }}
                  className="text-8xl"
                >
                  🧙‍♀️
                </motion.div>
                
                {/* Character glow halo */}
                <motion.div
                  className="absolute top-0 left-1/2 -translate-x-1/2 w-40 h-40 rounded-full bg-gradient-to-br from-purple-400/40 to-cyan-400/40 blur-2xl"
                  animate={{
                    scale: [1, 1.3, 1],
                    opacity: [0.4, 0.7, 0.4],
                  }}
                  transition={{
                    duration: 3,
                    repeat: Infinity,
                    ease: "easeInOut",
                  }}
                />
              </div>

              {/* Staff magical glow */}
              <motion.div
                className="absolute top-8 left-1/2 -translate-x-1/2 w-2 h-32 bg-gradient-to-b from-yellow-300/60 to-transparent blur-md"
                animate={{
                  opacity: [0.4, 1, 0.4],
                }}
                transition={{
                  duration: 2,
                  repeat: Infinity,
                  ease: "easeInOut",
                }}
              />

              {/* Familiar (Spirit Fox) floating next to character */}
              <motion.div
                animate={{
                  y: [0, -15, 0],
                  x: [0, 5, 0],
                }}
                transition={{
                  duration: 4,
                  repeat: Infinity,
                  ease: "easeInOut",
                  delay: 0.5,
                }}
                className="absolute -right-16 top-4 text-5xl z-20"
              >
                🦊
                
                {/* Familiar glow */}
                <motion.div
                  className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-24 h-24 rounded-full bg-gradient-to-br from-orange-400/40 to-yellow-400/40 blur-xl"
                  animate={{
                    scale: [1, 1.2, 1],
                    opacity: [0.3, 0.6, 0.3],
                  }}
                  transition={{
                    duration: 2.5,
                    repeat: Infinity,
                    ease: "easeInOut",
                  }}
                />
              </motion.div>
            </motion.div>
          </div>

          {/* Floating magical particles */}
          {Array.from({ length: 25 }).map((_, i) => (
            <motion.div
              key={i}
              className="absolute rounded-full"
              style={{
                left: `${15 + Math.random() * 70}%`,
                top: `${20 + Math.random() * 60}%`,
                width: Math.random() * 6 + 2,
                height: Math.random() * 6 + 2,
                background: ['#4FD1C5', '#805AD5', '#F6E05E', '#F4E4C1'][Math.floor(Math.random() * 4)],
              }}
              animate={{
                y: [0, -50 - Math.random() * 50, -100 - Math.random() * 50],
                x: [0, (Math.random() - 0.5) * 40],
                opacity: [0, 0.8, 0],
                scale: [0.5, 1.2, 0.5],
              }}
              transition={{
                duration: Math.random() * 4 + 3,
                repeat: Infinity,
                delay: Math.random() * 3,
                ease: "easeOut",
              }}
            />
          ))}

          {/* Sparkles around character */}
          {Array.from({ length: 8 }).map((_, i) => {
            const angle = (i * 45) * Math.PI / 180;
            const distance = 120;
            return (
              <motion.div
                key={`sparkle-${i}`}
                className="absolute text-yellow-300 text-2xl"
                style={{
                  left: '50%',
                  top: '50%',
                }}
                animate={{
                  x: Math.cos(angle) * distance,
                  y: Math.sin(angle) * distance,
                  opacity: [0, 1, 0],
                  scale: [0, 1, 0],
                  rotate: [0, 180],
                }}
                transition={{
                  duration: 2,
                  repeat: Infinity,
                  delay: i * 0.25,
                  ease: "easeOut",
                }}
              >
                ✨
              </motion.div>
            );
          })}
        </div>

        {/* Quick Actions Carousel - Parchment style cards */}
        <div className="px-6 pb-2">
          <div className="flex gap-3 overflow-x-auto pb-2 scrollbar-hide">
            {quickActions.map((action, index) => (
              <motion.button
                key={action.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.4, delay: 0.8 + index * 0.1 }}
                onClick={() => onNavigate('quest-creation')}
                className="relative flex-shrink-0 w-36 h-44 group"
              >
                {/* Ornate golden frame */}
                <svg viewBox="0 0 140 180" className="absolute inset-0 w-full h-full">
                  <defs>
                    <linearGradient id={`frameGold${action.id}`} x1="0%" y1="0%" x2="100%" y2="100%">
                      <stop offset="0%" stopColor="#D4AF37" />
                      <stop offset="50%" stopColor="#F4E4C1" />
                      <stop offset="100%" stopColor="#C19A3B" />
                    </linearGradient>
                  </defs>
                  
                  {/* Outer golden frame */}
                  <path
                    d="M 10,0 L 130,0 Q 140,10 140,20 L 140,160 Q 140,170 130,180 L 10,180 Q 0,170 0,160 L 0,20 Q 0,10 10,0"
                    fill={`url(#frameGold${action.id})`}
                  />
                  
                  {/* Inner parchment */}
                  <path
                    d="M 15,5 L 125,5 Q 135,12 135,22 L 135,158 Q 135,168 125,175 L 15,175 Q 5,168 5,158 L 5,22 Q 5,12 15,5"
                    fill="#FFFAF0"
                  />
                  
                  {/* Decorative corners */}
                  <circle cx="20" cy="20" r="3" fill="#C19A3B" />
                  <circle cx="120" cy="20" r="3" fill="#C19A3B" />
                  <circle cx="20" cy="160" r="3" fill="#C19A3B" />
                  <circle cx="120" cy="160" r="3" fill="#C19A3B" />
                  
                  {/* Top ornament */}
                  <path d="M 70,8 L 75,15 L 65,15 Z" fill="#C19A3B" />
                </svg>

                {/* Content */}
                <div className="absolute inset-0 flex flex-col items-center justify-center p-4">
                  {/* Item icon with background */}
                  <div className={`w-16 h-16 rounded-lg bg-gradient-to-br ${action.color} border-2 ${action.borderColor} flex items-center justify-center mb-3 group-hover:scale-110 transition-transform duration-300`}>
                    <span className="text-3xl">{action.icon}</span>
                  </div>
                  
                  {/* Title */}
                  <p className="text-amber-900 text-sm font-semibold text-center leading-tight">
                    {action.title}
                  </p>
                </div>

                {/* Hover glow */}
                <div className="absolute inset-0 rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-300 pointer-events-none">
                  <div className="absolute inset-0 bg-yellow-300/20 blur-xl rounded-2xl" />
                </div>
              </motion.button>
            ))}

            {/* See all quests card */}
            <motion.button
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, delay: 1.1 }}
              onClick={() => onNavigate('quests')}
              className="relative flex-shrink-0 w-36 h-44 flex items-center justify-center group"
            >
              {/* Same ornate frame */}
              <svg viewBox="0 0 140 180" className="absolute inset-0 w-full h-full">
                <defs>
                  <linearGradient id="frameGoldAll" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" stopColor="#D4AF37" />
                    <stop offset="50%" stopColor="#F4E4C1" />
                    <stop offset="100%" stopColor="#C19A3B" />
                  </linearGradient>
                </defs>
                <path
                  d="M 10,0 L 130,0 Q 140,10 140,20 L 140,160 Q 140,170 130,180 L 10,180 Q 0,170 0,160 L 0,20 Q 0,10 10,0"
                  fill="url(#frameGoldAll)"
                />
                <path
                  d="M 15,5 L 125,5 Q 135,12 135,22 L 135,158 Q 135,168 125,175 L 15,175 Q 5,168 5,158 L 5,22 Q 5,12 15,5"
                  fill="#FFFAF0"
                />
                <circle cx="20" cy="20" r="3" fill="#C19A3B" />
                <circle cx="120" cy="20" r="3" fill="#C19A3B" />
                <circle cx="20" cy="160" r="3" fill="#C19A3B" />
                <circle cx="120" cy="160" r="3" fill="#C19A3B" />
              </svg>

              <div className="absolute inset-0 flex flex-col items-center justify-center">
                <div className="text-4xl mb-2">📜</div>
                <p className="text-amber-900 text-xs font-semibold">Voir tout</p>
              </div>

              {/* Hover glow */}
              <div className="absolute inset-0 rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-300 pointer-events-none">
                <div className="absolute inset-0 bg-yellow-300/20 blur-xl rounded-2xl" />
              </div>
            </motion.button>
          </div>
        </div>
      </div>

      {/* FAB - Create Quest */}
      <motion.button
        initial={{ scale: 0, rotate: -180 }}
        animate={{ scale: 1, rotate: 0 }}
        transition={{ type: 'spring', stiffness: 260, damping: 20, delay: 1 }}
        onClick={() => onNavigate('quest-creation')}
        className="absolute bottom-24 left-1/2 -translate-x-1/2 z-40 w-16 h-16 rounded-full bg-gradient-to-br from-yellow-400 via-yellow-500 to-yellow-600 shadow-[0_0_30px_rgba(251,191,36,0.6)] border-4 border-yellow-300/50 flex items-center justify-center hover:scale-110 active:scale-95 transition-all duration-300"
      >
        <Plus size={32} className="text-amber-900" strokeWidth={3} />
        
        {/* Pulsing glow */}
        <motion.div
          className="absolute inset-0 rounded-full bg-yellow-400/40"
          animate={{
            scale: [1, 1.4, 1],
            opacity: [0.5, 0, 0.5],
          }}
          transition={{
            duration: 2,
            repeat: Infinity,
            ease: 'easeInOut',
          }}
        />
      </motion.button>

      {/* Bottom ornate border */}
      <div className="absolute bottom-0 left-0 right-0 h-20 pointer-events-none z-30">
        <svg viewBox="0 0 560 80" className="w-full h-full" preserveAspectRatio="none">
          <defs>
            <linearGradient id="bottomGold" x1="0%" y1="100%" x2="0%" y2="0%">
              <stop offset="0%" stopColor="#D4AF37" />
              <stop offset="50%" stopColor="#F4E4C1" />
              <stop offset="100%" stopColor="#C19A3B" />
            </linearGradient>
          </defs>
          <path
            d="M 0,80 L 560,80 L 560,20 Q 560,5 540,0 L 20,0 Q 0,5 0,20 Z"
            fill="url(#bottomGold)"
            opacity="0.9"
          />
          <path
            d="M 10,72 L 550,72 L 550,25 Q 550,12 535,8 L 25,8 Q 10,12 10,25 Z"
            fill="#3D2817"
            opacity="0.6"
          />
        </svg>
      </div>
    </div>
  );
}