import { useState } from 'react';
import { motion } from 'motion/react';
import { Heart, Users, Trophy, Zap } from 'lucide-react';
import type { UserData } from '../App';

interface SocialProps {
  userData: UserData;
}

interface Friend {
  id: string;
  name: string;
  level: number;
  avatar: string;
  title: string;
  xp: number;
  encouraged: boolean;
}

const mockFriends: Friend[] = [
  { id: '1', name: 'Aria', level: 15, avatar: '🧙‍♀️', title: 'Mage Stellaire', xp: 8450, encouraged: false },
  { id: '2', name: 'Kael', level: 12, avatar: '⚔️', title: 'Chevalier Lunaire', xp: 7200, encouraged: false },
  { id: '3', name: 'Luna', level: 18, avatar: '🦊', title: 'Gardienne des Âmes', xp: 9800, encouraged: false },
  { id: '4', name: 'Orion', level: 10, avatar: '🏹', title: 'Archer Mystique', xp: 5600, encouraged: false },
  { id: '5', name: 'Nova', level: 14, avatar: '✨', title: 'Enchanteresse', xp: 7950, encouraged: false },
];

export function Social({ userData }: SocialProps) {
  const [friends, setFriends] = useState<Friend[]>(mockFriends);

  const handleEncourage = (friendId: string) => {
    setFriends(prev => prev.map(friend => 
      friend.id === friendId ? { ...friend, encouraged: true } : friend
    ));
  };

  return (
    <div className="h-full flex flex-col px-4 pt-6 pb-24">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="mb-6"
      >
        <h1 className="text-cream-100 text-2xl tracking-wide mb-1 font-fantasy">Le Cercle</h1>
        <p className="text-purple-300/60 text-sm">Connecte-toi avec d'autres voyageurs</p>
      </motion.div>

      {/* Stats Cards */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.1 }}
        className="grid grid-cols-2 gap-3 mb-6"
      >
        <div className="bg-gradient-to-br from-purple-500/20 to-blue-500/20 p-4 rounded-2xl border border-purple-400/30 backdrop-blur-sm">
          <div className="flex items-center gap-2 mb-1">
            <Users size={16} className="text-purple-300" />
            <span className="text-purple-200 text-xs">Amis</span>
          </div>
          <p className="text-white text-2xl font-semibold">{friends.length}</p>
        </div>

        <div className="bg-gradient-to-br from-yellow-500/20 to-orange-500/20 p-4 rounded-2xl border border-yellow-400/30 backdrop-blur-sm">
          <div className="flex items-center gap-2 mb-1">
            <Trophy size={16} className="text-yellow-300" />
            <span className="text-yellow-200 text-xs">Rang</span>
          </div>
          <p className="text-white text-2xl font-semibold">#47</p>
        </div>
      </motion.div>

      {/* Friends List */}
      <div className="flex-1 overflow-y-auto">
        <div className="space-y-3">
          {friends.map((friend, index) => (
            <motion.div
              key={friend.id}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.4, delay: 0.2 + index * 0.1 }}
              className="relative bg-gradient-to-r from-purple-900/30 to-blue-900/30 p-4 rounded-2xl border border-purple-400/20 backdrop-blur-sm hover:border-purple-400/40 transition-all duration-300"
            >
              <div className="flex items-center gap-3">
                {/* Avatar */}
                <div className="w-12 h-12 rounded-full bg-gradient-to-br from-purple-300/30 to-blue-300/30 border-2 border-purple-300/50 flex items-center justify-center text-2xl flex-shrink-0">
                  {friend.avatar}
                </div>

                {/* Info */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-0.5">
                    <h3 className="text-white font-semibold truncate">{friend.name}</h3>
                    <span className="px-2 py-0.5 bg-purple-500/30 rounded-full text-purple-200 text-xs font-semibold border border-purple-400/30">
                      Niv. {friend.level}
                    </span>
                  </div>
                  <p className="text-purple-300/60 text-xs truncate">{friend.title}</p>
                  
                  {/* XP Progress */}
                  <div className="mt-2 flex items-center gap-2">
                    <div className="flex-1 h-1.5 bg-purple-950/50 rounded-full overflow-hidden">
                      <div 
                        className="h-full bg-gradient-to-r from-purple-400 to-blue-400 rounded-full"
                        style={{ width: `${(friend.xp % 1000) / 10}%` }}
                      />
                    </div>
                    <span className="text-purple-300/40 text-xs font-mono">{friend.xp}</span>
                  </div>
                </div>

                {/* Encourage Button */}
                <button
                  onClick={() => handleEncourage(friend.id)}
                  disabled={friend.encouraged}
                  className={`relative p-3 rounded-full transition-all duration-300 ${
                    friend.encouraged
                      ? 'bg-red-500/30 border-2 border-red-400'
                      : 'bg-purple-500/20 border-2 border-purple-400/30 hover:bg-purple-500/30 active:scale-95'
                  }`}
                >
                  <Heart 
                    size={20} 
                    className={friend.encouraged ? 'text-red-400 fill-red-400' : 'text-purple-300'} 
                  />
                  
                  {/* Particles when encouraged */}
                  {friend.encouraged && (
                    <>
                      {Array.from({ length: 6 }).map((_, i) => {
                        const angle = (i * 60) - 30;
                        const distance = 40;
                        const x = Math.cos((angle * Math.PI) / 180) * distance;
                        const y = Math.sin((angle * Math.PI) / 180) * distance;
                        
                        return (
                          <motion.div
                            key={i}
                            className="absolute top-1/2 left-1/2 w-2 h-2"
                            initial={{ x: 0, y: 0, opacity: 1, scale: 1 }}
                            animate={{
                              x,
                              y: y - 20,
                              opacity: 0,
                              scale: 0,
                            }}
                            transition={{
                              duration: 0.8,
                              delay: i * 0.05,
                              ease: 'easeOut',
                            }}
                          >
                            ❤️
                          </motion.div>
                        );
                      })}
                    </>
                  )}
                </button>
              </div>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Action Buttons */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.6 }}
        className="mt-4 flex gap-3"
      >
        <button className="flex-1 h-12 rounded-full bg-gradient-to-r from-purple-500 to-blue-500 text-white font-semibold flex items-center justify-center gap-2 shadow-lg shadow-purple-500/30 hover:shadow-purple-500/50 active:scale-95 transition-all duration-300">
          <Users size={18} />
          <span>Trouver des amis</span>
        </button>
        
        <button className="h-12 w-12 rounded-full bg-gradient-to-br from-yellow-500/20 to-orange-500/20 border border-yellow-400/30 flex items-center justify-center shadow-lg hover:bg-yellow-500/30 active:scale-95 transition-all duration-300">
          <Trophy size={18} className="text-yellow-300" />
        </button>
      </motion.div>
    </div>
  );
}