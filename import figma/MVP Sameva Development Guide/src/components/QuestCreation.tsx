import { useState } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, BookOpen, Dumbbell, Heart, Palette, Users, Sparkles } from 'lucide-react';
import type { Page, Quest } from '../App';

interface QuestCreationProps {
  onNavigate: (page: Page) => void;
  onCreateQuest: (quest: Omit<Quest, 'id' | 'status' | 'progress'>) => void;
}

type Category = 'study' | 'sport' | 'selfcare' | 'creative' | 'social';
type Difficulty = 'easy' | 'medium' | 'hard';

const categories = [
  { id: 'study' as Category, icon: BookOpen, label: 'Étude', color: 'blue' },
  { id: 'sport' as Category, icon: Dumbbell, label: 'Sport', color: 'red' },
  { id: 'selfcare' as Category, icon: Heart, label: 'Bien-être', color: 'pink' },
  { id: 'creative' as Category, icon: Palette, label: 'Créativité', color: 'purple' },
  { id: 'social' as Category, icon: Users, label: 'Social', color: 'green' },
];

const difficulties = [
  { id: 'easy' as Difficulty, label: 'Facile', xp: 50, gold: 20, color: 'green' },
  { id: 'medium' as Difficulty, label: 'Moyen', xp: 120, gold: 50, color: 'yellow' },
  { id: 'hard' as Difficulty, label: 'Difficile', xp: 200, gold: 100, color: 'red' },
];

export function QuestCreation({ onNavigate, onCreateQuest }: QuestCreationProps) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [category, setCategory] = useState<Category>('study');
  const [difficulty, setDifficulty] = useState<Difficulty>('medium');

  const handleSubmit = () => {
    if (!title.trim()) return;

    const selectedDifficulty = difficulties.find(d => d.id === difficulty)!;
    
    onCreateQuest({
      title: title.trim(),
      description: description.trim(),
      category,
      difficulty,
      rewards: {
        xp: selectedDifficulty.xp,
        gold: selectedDifficulty.gold,
      },
    });

    onNavigate('sanctuary');
  };

  return (
    <div className="min-h-screen px-4 pt-8 pb-8">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="mb-8"
      >
        <div className="flex items-center gap-3 mb-4">
          <button
            onClick={() => onNavigate('sanctuary')}
            className="p-2 rounded-full bg-purple-500/20 border border-purple-400/30 hover:bg-purple-500/30 transition-all duration-300"
          >
            <ArrowLeft size={20} className="text-purple-200" />
          </button>
          <div>
            <h1 className="text-cream-100 text-2xl tracking-wide">Nouvelle Quête</h1>
            <p className="text-purple-300/60 text-sm">Crée ton prochain défi</p>
          </div>
        </div>
      </motion.div>

      {/* Form */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.1 }}
        className="space-y-6"
      >
        {/* Title Input */}
        <div>
          <label className="block text-purple-200 mb-2 text-sm">Titre de la quête</label>
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Ex: Méditer 15 minutes"
            className="w-full px-4 py-3 bg-purple-950/30 border border-purple-400/30 rounded-xl text-purple-100 placeholder:text-purple-400/40 focus:outline-none focus:border-purple-400/60 focus:shadow-[0_0_20px_rgba(168,85,247,0.3)] transition-all duration-300"
          />
        </div>

        {/* Description Input */}
        <div>
          <label className="block text-purple-200 mb-2 text-sm">Description (optionnelle)</label>
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="Décris ta quête..."
            rows={3}
            className="w-full px-4 py-3 bg-purple-950/30 border border-purple-400/30 rounded-xl text-purple-100 placeholder:text-purple-400/40 focus:outline-none focus:border-purple-400/60 focus:shadow-[0_0_20px_rgba(168,85,247,0.3)] transition-all duration-300 resize-none"
          />
        </div>

        {/* Category Selection */}
        <div>
          <label className="block text-purple-200 mb-3 text-sm">Catégorie</label>
          <div className="grid grid-cols-3 gap-2">
            {categories.map((cat) => {
              const Icon = cat.icon;
              const isSelected = category === cat.id;
              
              return (
                <button
                  key={cat.id}
                  onClick={() => setCategory(cat.id)}
                  className={`relative p-3 rounded-xl border transition-all duration-300 ${
                    isSelected
                      ? 'bg-purple-500/30 border-purple-400/60 shadow-[0_0_20px_rgba(168,85,247,0.4)]'
                      : 'bg-purple-950/20 border-purple-500/20 hover:border-purple-400/40'
                  }`}
                >
                  <div className="flex flex-col items-center gap-2">
                    <Icon 
                      size={24} 
                      className={isSelected ? 'text-purple-200' : 'text-purple-400/60'}
                    />
                    <span className={`text-xs ${isSelected ? 'text-purple-100' : 'text-purple-400/60'}`}>
                      {cat.label}
                    </span>
                  </div>
                  
                  {isSelected && (
                    <motion.div
                      layoutId="categoryGlow"
                      className="absolute inset-0 bg-gradient-to-br from-purple-400/20 to-blue-400/20 rounded-xl -z-10 blur-lg"
                      initial={false}
                      transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                    />
                  )}
                </button>
              );
            })}
          </div>
        </div>

        {/* Difficulty Selection */}
        <div>
          <label className="block text-purple-200 mb-3 text-sm">Difficulté</label>
          <div className="space-y-2">
            {difficulties.map((diff) => {
              const isSelected = difficulty === diff.id;
              
              return (
                <button
                  key={diff.id}
                  onClick={() => setDifficulty(diff.id)}
                  className={`w-full p-4 rounded-xl border transition-all duration-300 ${
                    isSelected
                      ? 'bg-gradient-to-br from-purple-500/30 to-blue-500/30 border-purple-400/60 shadow-[0_0_20px_rgba(168,85,247,0.4)]'
                      : 'bg-purple-950/20 border-purple-500/20 hover:border-purple-400/40'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className={`w-3 h-3 rounded-full ${
                        diff.color === 'green' ? 'bg-green-400' :
                        diff.color === 'yellow' ? 'bg-yellow-400' :
                        'bg-red-400'
                      } ${isSelected ? 'shadow-[0_0_10px_currentColor]' : ''}`} />
                      <span className={isSelected ? 'text-purple-100' : 'text-purple-400/60'}>
                        {diff.label}
                      </span>
                    </div>
                    <div className="flex items-center gap-4">
                      <span className={`text-sm ${isSelected ? 'text-yellow-300' : 'text-purple-400/40'}`}>
                        +{diff.xp} XP
                      </span>
                      <span className={`text-sm ${isSelected ? 'text-yellow-300' : 'text-purple-400/40'}`}>
                        +{diff.gold} 🪙
                      </span>
                    </div>
                  </div>
                </button>
              );
            })}
          </div>
        </div>

        {/* Submit Button */}
        <motion.button
          onClick={handleSubmit}
          disabled={!title.trim()}
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
          className={`w-full py-4 rounded-xl transition-all duration-300 flex items-center justify-center gap-2 ${
            title.trim()
              ? 'bg-gradient-to-r from-purple-500 to-blue-500 shadow-[0_0_30px_rgba(168,85,247,0.5)] hover:shadow-[0_0_40px_rgba(168,85,247,0.7)]'
              : 'bg-purple-950/30 opacity-50 cursor-not-allowed'
          }`}
        >
          <Sparkles size={20} className="text-white" />
          <span className="text-white">Créer la quête</span>
        </motion.button>
      </motion.div>
    </div>
  );
}
