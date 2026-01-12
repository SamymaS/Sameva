import { motion } from 'motion/react';
import { User, Trophy, Zap, Calendar, Settings, ChevronRight, Award, Target, Sparkles } from 'lucide-react';
import type { UserData } from '../App';

interface ProfileProps {
  userData: UserData;
}

export function Profile({ userData }: ProfileProps) {
  const achievements = [
    { id: 1, name: 'Premier Pas', description: 'Créer ta première quête', icon: '🎯', unlocked: true },
    { id: 2, name: 'Persévérant', description: 'Compléter 10 quêtes', icon: '💪', unlocked: true },
    { id: 3, name: 'Maître Mystique', description: 'Atteindre le niveau 10', icon: '🌟', unlocked: true },
    { id: 4, name: 'Collectionneur', description: 'Obtenir 20 objets', icon: '📦', unlocked: false },
    { id: 5, name: 'Légende', description: 'Atteindre le niveau 50', icon: '👑', unlocked: false },
  ];

  const stats = [
    { label: 'Quêtes complétées', value: '47', icon: Target },
    { label: 'Jours actifs', value: '23', icon: Calendar },
    { label: 'Objets collectés', value: '15', icon: Sparkles },
    { label: 'Niveau max atteint', value: userData.level.toString(), icon: Trophy },
  ];

  return (
    <div className="min-h-screen px-4 pt-8 pb-8">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="mb-6"
      >
        <div className="flex items-center justify-between mb-6">
          <div>
            <h1 className="text-cream-100 text-2xl tracking-wide mb-1">Profil</h1>
            <p className="text-purple-300/60 text-sm">Ton parcours mystique</p>
          </div>

          <button className="p-2 rounded-full bg-purple-500/20 border border-purple-400/30 hover:bg-purple-500/30 transition-all duration-300">
            <Settings size={20} className="text-purple-200" />
          </button>
        </div>
      </motion.div>

      {/* Profile Card */}
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.5, delay: 0.1 }}
        className="relative mb-6 p-6 bg-gradient-to-br from-purple-900/40 to-blue-900/40 rounded-3xl border border-purple-400/30 overflow-hidden shadow-[0_8px_40px_rgba(139,92,246,0.3)]"
      >
        {/* Background glow */}
        <div className="absolute top-0 right-0 w-48 h-48 bg-purple-500/20 rounded-full blur-3xl" />
        
        <div className="relative flex items-center gap-4 mb-4">
          {/* Avatar */}
          <div className="relative w-20 h-20 rounded-2xl bg-gradient-to-br from-purple-300/30 to-blue-300/30 border-2 border-purple-300/50 shadow-[0_0_30px_rgba(216,180,254,0.6)] flex items-center justify-center">
            <span className="text-5xl">🧙‍♀️</span>
            
            {/* Level badge */}
            <div className="absolute -bottom-2 -right-2 w-8 h-8 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-full flex items-center justify-center text-white text-xs border-2 border-purple-950">
              {userData.level}
            </div>
          </div>

          {/* Info */}
          <div className="flex-1">
            <h2 className="text-purple-100 text-xl mb-1">{userData.name}</h2>
            <p className="text-purple-300/60 text-sm mb-2">Voyageur Mystique</p>
            
            {/* XP Bar */}
            <div className="flex items-center gap-2">
              <div className="flex-1 h-2 bg-purple-950/50 rounded-full overflow-hidden">
                <motion.div
                  className="h-full bg-gradient-to-r from-purple-400 to-blue-400"
                  initial={{ width: 0 }}
                  animate={{ width: `${(userData.xp / userData.maxXp) * 100}%` }}
                  transition={{ duration: 1, delay: 0.3 }}
                />
              </div>
              <span className="text-purple-300/60 text-xs">{userData.xp}/{userData.maxXp}</span>
            </div>
          </div>
        </div>

        {/* Resources */}
        <div className="relative flex gap-3">
          <div className="flex-1 bg-gradient-to-br from-yellow-500/20 to-orange-500/20 rounded-xl p-3 border border-yellow-400/30">
            <p className="text-yellow-300/60 text-xs mb-1">Or</p>
            <p className="text-yellow-100">{userData.gold}</p>
          </div>
          <div className="flex-1 bg-gradient-to-br from-blue-500/20 to-cyan-500/20 rounded-xl p-3 border border-blue-400/30">
            <p className="text-cyan-300/60 text-xs mb-1">Gemmes</p>
            <p className="text-cyan-100">{userData.gems}</p>
          </div>
        </div>
      </motion.div>

      {/* Stats Grid */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.2 }}
        className="mb-6"
      >
        <h3 className="text-purple-200 mb-3 flex items-center gap-2">
          <Trophy size={18} />
          <span>Statistiques</span>
        </h3>

        <div className="grid grid-cols-2 gap-3">
          {stats.map((stat, index) => {
            const Icon = stat.icon;
            
            return (
              <motion.div
                key={stat.label}
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ duration: 0.3, delay: 0.3 + index * 0.05 }}
                className="p-4 bg-gradient-to-br from-purple-900/30 to-blue-900/30 rounded-xl border border-purple-400/20"
              >
                <div className="flex items-center gap-2 mb-2">
                  <div className="w-8 h-8 rounded-lg bg-purple-500/20 flex items-center justify-center border border-purple-400/30">
                    <Icon size={16} className="text-purple-300" />
                  </div>
                </div>
                <p className="text-purple-100 text-xl mb-1">{stat.value}</p>
                <p className="text-purple-300/50 text-xs">{stat.label}</p>
              </motion.div>
            );
          })}
        </div>
      </motion.div>

      {/* Achievements */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.4 }}
        className="mb-6"
      >
        <h3 className="text-purple-200 mb-3 flex items-center gap-2">
          <Award size={18} />
          <span>Accomplissements</span>
        </h3>

        <div className="space-y-2">
          {achievements.map((achievement, index) => (
            <motion.div
              key={achievement.id}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.3, delay: 0.5 + index * 0.05 }}
              className={`p-3 rounded-xl border transition-all duration-300 ${
                achievement.unlocked
                  ? 'bg-gradient-to-br from-purple-900/30 to-blue-900/30 border-purple-400/30'
                  : 'bg-purple-950/20 border-purple-500/10 opacity-50'
              }`}
            >
              <div className="flex items-center gap-3">
                <div className={`w-12 h-12 rounded-xl flex items-center justify-center border ${
                  achievement.unlocked
                    ? 'bg-purple-500/20 border-purple-400/40'
                    : 'bg-purple-950/20 border-purple-500/20'
                }`}>
                  <span className="text-3xl">{achievement.icon}</span>
                </div>

                <div className="flex-1">
                  <h4 className={achievement.unlocked ? 'text-purple-100' : 'text-purple-400/40'}>
                    {achievement.name}
                  </h4>
                  <p className={`text-xs ${achievement.unlocked ? 'text-purple-300/60' : 'text-purple-400/30'}`}>
                    {achievement.description}
                  </p>
                </div>

                {achievement.unlocked && (
                  <div className="w-6 h-6 rounded-full bg-gradient-to-br from-green-400 to-emerald-500 flex items-center justify-center">
                    <Zap size={14} className="text-white" />
                  </div>
                )}
              </div>
            </motion.div>
          ))}
        </div>
      </motion.div>

      {/* Settings Section */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.7 }}
      >
        <h3 className="text-purple-200 mb-3 flex items-center gap-2">
          <Settings size={18} />
          <span>Paramètres</span>
        </h3>

        <div className="space-y-2">
          {[
            { label: 'Notifications', icon: '🔔' },
            { label: 'Confidentialité', icon: '🔒' },
            { label: 'Son et musique', icon: '🎵' },
            { label: 'À propos', icon: 'ℹ️' },
          ].map((item, index) => (
            <motion.button
              key={item.label}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.3, delay: 0.8 + index * 0.05 }}
              className="w-full p-4 bg-gradient-to-br from-purple-900/30 to-blue-900/30 rounded-xl border border-purple-400/20 hover:border-purple-400/40 transition-all duration-300 flex items-center justify-between"
            >
              <div className="flex items-center gap-3">
                <span className="text-2xl">{item.icon}</span>
                <span className="text-purple-100">{item.label}</span>
              </div>
              <ChevronRight size={20} className="text-purple-400/60" />
            </motion.button>
          ))}
        </div>
      </motion.div>
    </div>
  );
}
