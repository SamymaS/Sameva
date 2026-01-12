import { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { ArrowLeft, Check, Clock, Calendar, BookOpen, Dumbbell, Heart, Palette, Users } from 'lucide-react';
import type { Quest } from '../App';

interface QuestListProps {
  quests: Quest[];
  onCompleteQuest: (questId: string) => void;
  onNavigate: (page: any) => void;
}

type FilterType = 'all' | 'active' | 'completed' | 'upcoming';

const categoryIcons = {
  study: BookOpen,
  sport: Dumbbell,
  selfcare: Heart,
  creative: Palette,
  social: Users,
};

export function QuestList({ quests, onCompleteQuest, onNavigate }: QuestListProps) {
  const [filter, setFilter] = useState<FilterType>('all');

  const filteredQuests = quests.filter(quest => {
    if (filter === 'all') return true;
    return quest.status === filter;
  });

  const filters = [
    { id: 'all' as FilterType, label: 'Toutes', count: quests.length },
    { id: 'active' as FilterType, label: 'En cours', count: quests.filter(q => q.status === 'active').length },
    { id: 'completed' as FilterType, label: 'Terminées', count: quests.filter(q => q.status === 'completed').length },
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
        <div className="flex items-center gap-3 mb-6">
          <button
            onClick={() => onNavigate('sanctuary')}
            className="p-2 rounded-full bg-purple-500/20 border border-purple-400/30 hover:bg-purple-500/30 transition-all duration-300"
          >
            <ArrowLeft size={20} className="text-purple-200" />
          </button>
          <div>
            <h1 className="text-cream-100 text-2xl tracking-wide">Mes Quêtes</h1>
            <p className="text-purple-300/60 text-sm">Suis ta progression</p>
          </div>
        </div>

        {/* Filters */}
        <div className="flex gap-2 overflow-x-auto pb-2 snap-x snap-mandatory touch-pan-x">
          {filters.map((filterItem) => {
            const isActive = filter === filterItem.id;
            
            return (
              <button
                key={filterItem.id}
                onClick={() => setFilter(filterItem.id)}
                className={`relative px-4 py-2 rounded-full whitespace-nowrap transition-all duration-300 ${
                  isActive
                    ? 'bg-gradient-to-r from-purple-500/30 to-blue-500/30 border border-purple-400/50 shadow-[0_0_20px_rgba(168,85,247,0.4)]'
                    : 'bg-purple-950/20 border border-purple-500/20 hover:border-purple-400/40'
                }`}
              >
                <span className={isActive ? 'text-purple-100' : 'text-purple-400/60'}>
                  {filterItem.label} ({filterItem.count})
                </span>
                
                {isActive && (
                  <motion.div
                    layoutId="filterGlow"
                    className="absolute inset-0 bg-gradient-to-r from-purple-400/20 to-blue-400/20 rounded-full -z-10 blur-xl"
                    initial={false}
                    transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                  />
                )}
              </button>
            );
          })}
        </div>
      </motion.div>

      {/* Quest List */}
      <AnimatePresence mode="popLayout">
        {filteredQuests.length === 0 ? (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="text-center py-16"
          >
            <div className="w-24 h-24 mx-auto mb-4 rounded-full bg-purple-500/10 flex items-center justify-center border border-purple-400/20">
              <Calendar size={40} className="text-purple-400/40" />
            </div>
            <p className="text-purple-300/40">Aucune quête trouvée</p>
          </motion.div>
        ) : (
          <div className="space-y-3">
            {filteredQuests.map((quest, index) => {
              const Icon = categoryIcons[quest.category];
              const isCompleted = quest.status === 'completed';
              
              return (
                <motion.div
                  key={quest.id}
                  layout
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: 20 }}
                  transition={{ duration: 0.3, delay: index * 0.05 }}
                  className={`relative p-4 rounded-2xl border transition-all duration-300 overflow-hidden ${
                    isCompleted
                      ? 'bg-gradient-to-br from-green-900/20 to-blue-900/20 border-green-400/30'
                      : 'bg-gradient-to-br from-purple-900/30 to-blue-900/30 border-purple-400/20 hover:border-purple-400/40'
                  }`}
                >
                  {/* Background glow */}
                  <div className={`absolute inset-0 opacity-0 hover:opacity-100 transition-opacity duration-300 ${
                    isCompleted
                      ? 'bg-gradient-to-br from-green-400/5 to-blue-400/5'
                      : 'bg-gradient-to-br from-purple-400/5 to-blue-400/5'
                  }`} />

                  <div className="relative flex items-start gap-4">
                    {/* Icon */}
                    <div className={`flex-shrink-0 w-12 h-12 rounded-xl flex items-center justify-center border ${
                      isCompleted
                        ? 'bg-green-500/20 border-green-400/40'
                        : 'bg-purple-500/20 border-purple-400/30'
                    }`}>
                      {isCompleted ? (
                        <Check size={24} className="text-green-300" />
                      ) : (
                        <Icon size={24} className="text-purple-300" />
                      )}
                    </div>

                    {/* Content */}
                    <div className="flex-1 min-w-0">
                      <h3 className={`mb-1 ${isCompleted ? 'text-green-100 line-through' : 'text-purple-100'}`}>
                        {quest.title}
                      </h3>
                      
                      {quest.description && (
                        <p className="text-purple-300/50 text-sm mb-2 line-clamp-2">
                          {quest.description}
                        </p>
                      )}

                      {/* Progress Bar */}
                      {!isCompleted && (
                        <div className="mb-2">
                          <div className="h-1.5 bg-purple-950/50 rounded-full overflow-hidden">
                            <motion.div
                              className="h-full bg-gradient-to-r from-purple-400 to-blue-400 rounded-full"
                              initial={{ width: 0 }}
                              animate={{ width: `${quest.progress || 0}%` }}
                              transition={{ duration: 0.8 }}
                            />
                          </div>
                          <div className="flex justify-between mt-1">
                            <span className="text-purple-300/40 text-xs">{quest.progress || 0}%</span>
                          </div>
                        </div>
                      )}

                      {/* Rewards */}
                      <div className="flex items-center gap-3">
                        <div className="flex items-center gap-1 text-sm text-yellow-300/80">
                          <span>+{quest.rewards.xp} XP</span>
                        </div>
                        <div className="flex items-center gap-1 text-sm text-yellow-300/80">
                          <span>+{quest.rewards.gold} 🪙</span>
                        </div>
                        {quest.rewards.items && quest.rewards.items.length > 0 && (
                          <div className="flex items-center gap-1 text-sm text-purple-300/80">
                            <span>+Objet</span>
                          </div>
                        )}
                      </div>
                    </div>

                    {/* Action Button */}
                    {!isCompleted && (
                      <button
                        onClick={() => {
                          if (quest.progress === 100) {
                            onCompleteQuest(quest.id);
                          }
                        }}
                        disabled={quest.progress !== 100}
                        className={`flex-shrink-0 p-2.5 rounded-full transition-all duration-300 ${
                          quest.progress === 100
                            ? 'bg-gradient-to-br from-purple-500/30 to-blue-500/30 border border-purple-300/50 shadow-[0_0_15px_rgba(168,85,247,0.4)] hover:shadow-[0_0_25px_rgba(168,85,247,0.6)] cursor-pointer'
                            : 'bg-purple-950/30 border border-purple-500/20 opacity-50 cursor-not-allowed'
                        }`}
                      >
                        <Check size={20} className="text-purple-200" />
                      </button>
                    )}
                  </div>

                  {/* Difficulty badge */}
                  <div className={`absolute top-3 right-3 px-2 py-1 rounded-full text-xs ${
                    quest.difficulty === 'easy' ? 'bg-green-500/20 text-green-300 border border-green-400/30' :
                    quest.difficulty === 'medium' ? 'bg-yellow-500/20 text-yellow-300 border border-yellow-400/30' :
                    'bg-red-500/20 text-red-300 border border-red-400/30'
                  }`}>
                    {quest.difficulty === 'easy' ? 'Facile' : quest.difficulty === 'medium' ? 'Moyen' : 'Difficile'}
                  </div>

                  {isCompleted && (
                    <motion.div
                      className="absolute inset-0 border-2 border-green-400/20 rounded-2xl pointer-events-none"
                      initial={{ scale: 1, opacity: 0 }}
                      animate={{ scale: 1.05, opacity: [0, 1, 0] }}
                      transition={{ duration: 1.5, ease: 'easeOut' }}
                    />
                  )}
                </motion.div>
              );
            })}
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}
