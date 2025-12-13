import { motion } from 'motion/react';
import { Settings } from 'lucide-react';
import type { UserData, Page } from '../App';
import avatarImage from 'figma:asset/03d246e43912467c3303b8a0425b51ce68bda6c1.png';

interface HeaderBarProps {
  userData: UserData;
  onNavigate: (page: Page) => void;
}

export function HeaderBar({ userData, onNavigate }: HeaderBarProps) {
  return (
    <>
      {/* Ornate Golden Frame Top - BEHIND content */}
      <div className="absolute top-0 left-0 right-0 h-20 pointer-events-none z-0">
        {/* Top golden ornate border */}
        <svg viewBox="0 0 560 100" className="w-full h-full" preserveAspectRatio="none">
          <defs>
            <linearGradient id="goldGradient" x1="0%" y1="0%" x2="0%" y2="100%">
              <stop offset="0%" stopColor="#D4AF37" />
              <stop offset="50%" stopColor="#F4E4C1" />
              <stop offset="100%" stopColor="#C19A3B" />
            </linearGradient>
          </defs>
          {/* Ornate curved border */}
          <path
            d="M 0,0 L 560,0 L 560,50 Q 560,70 540,75 L 20,75 Q 0,70 0,50 Z"
            fill="url(#goldGradient)"
            opacity="0.9"
          />
          {/* Inner shadow */}
          <path
            d="M 10,8 L 550,8 L 550,48 Q 550,65 535,69 L 25,69 Q 10,65 10,48 Z"
            fill="#3D2817"
            opacity="0.6"
          />
          {/* Decorative patterns */}
          <circle cx="280" cy="75" r="6" fill="#C19A3B" />
          <circle cx="100" cy="65" r="4" fill="#F4E4C1" />
          <circle cx="460" cy="65" r="4" fill="#F4E4C1" />
        </svg>
      </div>

      {/* Header Content - ABOVE decorations with safe area */}
      <motion.div
        initial={{ y: -20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ duration: 0.6, delay: 0.2 }}
        className="fixed top-0 left-0 right-0 pt-2 px-4 flex items-center gap-3 z-50 bg-gradient-to-b from-black/40 via-black/20 to-transparent backdrop-blur-sm"
        style={{ paddingTop: 'max(0.5rem, env(safe-area-inset-top))' }}
      >
        {/* Avatar with ornate golden frame */}
        <div className="relative w-16 h-16 flex-shrink-0">
          {/* Golden circular frame */}
          <svg viewBox="0 0 80 80" className="absolute inset-0 w-full h-full">
            <defs>
              <linearGradient id="avatarFrameGold" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="#F4E4C1" />
                <stop offset="50%" stopColor="#D4AF37" />
                <stop offset="100%" stopColor="#C19A3B" />
              </linearGradient>
            </defs>
            <circle cx="40" cy="40" r="38" fill="url(#avatarFrameGold)" />
            <circle cx="40" cy="40" r="33" fill="#2D2420" />
            {/* Decorative notches */}
            <circle cx="40" cy="5" r="3" fill="#C19A3B" />
            <circle cx="5" cy="40" r="3" fill="#C19A3B" />
            <circle cx="75" cy="40" r="3" fill="#C19A3B" />
            <circle cx="40" cy="75" r="3" fill="#C19A3B" />
          </svg>
          
          {/* Avatar image placeholder */}
          <div className="absolute inset-2 rounded-full overflow-hidden bg-gradient-to-br from-purple-400 to-blue-500">
            <div className="w-full h-full flex items-center justify-center text-3xl">
              🧙‍♀️
            </div>
          </div>
        </div>

        {/* Name & XP Bar */}
        <div className="flex-1 min-w-0">
          <h2 className="text-white text-xl font-fantasy mb-1">Sameva</h2>
          
          {/* XP Bar */}
          <div className="relative w-full h-3 rounded-full overflow-hidden bg-[#2D2B55] border border-purple-800/50">
            {/* Label XP */}
            <span className="absolute left-1 top-0 text-[9px] text-purple-200/80 z-10 font-semibold tracking-wider">
              XP
            </span>
            
            {/* Progress fill */}
            <motion.div
              className="absolute inset-0 bg-gradient-to-r from-purple-500 via-purple-400 to-purple-500 rounded-full"
              initial={{ width: 0 }}
              animate={{ width: `${(userData.xp / userData.nextLevelXp) * 100}%` }}
              transition={{ duration: 1, delay: 0.5 }}
            />
            
            {/* Shine effect */}
            <div className="absolute inset-0 bg-gradient-to-b from-white/20 to-transparent rounded-full" />
          </div>
        </div>

        {/* Gold */}
        <div className="flex items-center gap-1.5 px-2.5 py-1.5 bg-gradient-to-br from-yellow-600/30 to-yellow-800/30 rounded-full border border-yellow-500/40 backdrop-blur-sm">
          <div className="w-5 h-5 rounded-full bg-gradient-to-br from-yellow-300 to-yellow-600 flex items-center justify-center">
            <span className="text-xs">🪙</span>
          </div>
          <span className="text-yellow-100 text-sm font-semibold">{userData.coins}</span>
        </div>

        {/* Gems */}
        <div className="flex items-center gap-1.5 px-2.5 py-1.5 bg-gradient-to-br from-cyan-600/30 to-blue-800/30 rounded-full border border-cyan-400/40 backdrop-blur-sm">
          <div className="w-5 h-5 rounded-full bg-gradient-to-br from-cyan-300 to-blue-500 flex items-center justify-center">
            <span className="text-xs">💎</span>
          </div>
          <span className="text-cyan-100 text-sm font-semibold">{userData.gems}</span>
        </div>

        {/* Settings */}
        <button
          onClick={() => onNavigate('settings')}
          className="w-9 h-9 rounded-full bg-gradient-to-br from-gray-400/20 to-gray-600/20 border border-gray-400/30 backdrop-blur-sm flex items-center justify-center hover:bg-gray-400/30 active:scale-95 transition-all duration-200"
        >
          <Settings size={18} className="text-gray-300" />
        </button>
      </motion.div>
    </>
  );
}