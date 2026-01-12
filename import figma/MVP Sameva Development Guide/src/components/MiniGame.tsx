import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Gamepad2, Trophy, Sparkles, RotateCcw } from 'lucide-react';

interface MiniGameProps {
  onReward: (gold: number, xp: number) => void;
}

type GameState = 'menu' | 'playing' | 'result';

export function MiniGame({ onReward }: MiniGameProps) {
  const [gameState, setGameState] = useState<GameState>('menu');
  const [score, setScore] = useState(0);
  const [timeLeft, setTimeLeft] = useState(30);
  const [sequence, setSequence] = useState<number[]>([]);
  const [playerSequence, setPlayerSequence] = useState<number[]>([]);
  const [isShowingSequence, setIsShowingSequence] = useState(false);
  const [activeButton, setActiveButton] = useState<number | null>(null);

  const colors = [
    { id: 0, color: 'from-purple-500 to-purple-600', activeColor: 'from-purple-300 to-purple-400' },
    { id: 1, color: 'from-blue-500 to-blue-600', activeColor: 'from-blue-300 to-blue-400' },
    { id: 2, color: 'from-pink-500 to-pink-600', activeColor: 'from-pink-300 to-pink-400' },
    { id: 3, color: 'from-cyan-500 to-cyan-600', activeColor: 'from-cyan-300 to-cyan-400' },
  ];

  useEffect(() => {
    if (gameState === 'playing' && timeLeft > 0) {
      const timer = setTimeout(() => setTimeLeft(timeLeft - 1), 1000);
      return () => clearTimeout(timer);
    } else if (timeLeft === 0 && gameState === 'playing') {
      endGame();
    }
  }, [timeLeft, gameState]);

  const startGame = () => {
    setGameState('playing');
    setScore(0);
    setTimeLeft(30);
    setSequence([]);
    setPlayerSequence([]);
    nextRound();
  };

  const nextRound = () => {
    const newSequence = [...sequence, Math.floor(Math.random() * 4)];
    setSequence(newSequence);
    setPlayerSequence([]);
    showSequence(newSequence);
  };

  const showSequence = async (seq: number[]) => {
    setIsShowingSequence(true);
    
    for (let i = 0; i < seq.length; i++) {
      await new Promise(resolve => setTimeout(resolve, 600));
      setActiveButton(seq[i]);
      await new Promise(resolve => setTimeout(resolve, 400));
      setActiveButton(null);
    }
    
    setIsShowingSequence(false);
  };

  const handleButtonClick = (buttonId: number) => {
    if (isShowingSequence || gameState !== 'playing') return;

    const newPlayerSequence = [...playerSequence, buttonId];
    setPlayerSequence(newPlayerSequence);
    setActiveButton(buttonId);
    setTimeout(() => setActiveButton(null), 200);

    // Check if correct
    if (buttonId !== sequence[newPlayerSequence.length - 1]) {
      // Wrong! End game
      endGame();
      return;
    }

    // Check if sequence complete
    if (newPlayerSequence.length === sequence.length) {
      setScore(score + sequence.length * 10);
      setTimeout(() => nextRound(), 1000);
    }
  };

  const endGame = () => {
    setGameState('result');
    const goldReward = Math.floor(score / 2);
    const xpReward = Math.floor(score / 5);
    onReward(goldReward, xpReward);
  };

  const resetGame = () => {
    setGameState('menu');
    setScore(0);
    setTimeLeft(30);
    setSequence([]);
    setPlayerSequence([]);
  };

  return (
    <div className="h-full px-4 pt-6 pb-20 flex flex-col">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="mb-6"
      >
        <h1 className="text-cream-100 text-2xl tracking-wide mb-1">Mini-Jeu</h1>
        <p className="text-purple-300/60 text-sm">Mémorise la séquence mystique</p>
      </motion.div>

      <AnimatePresence mode="wait">
        {/* Menu State */}
        {gameState === 'menu' && (
          <motion.div
            key="menu"
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            className="flex-1 flex flex-col items-center justify-center"
          >
            <motion.div
              animate={{
                rotate: [0, 5, -5, 0],
                scale: [1, 1.05, 1],
              }}
              transition={{
                duration: 4,
                repeat: Infinity,
                ease: 'easeInOut',
              }}
              className="w-32 h-32 bg-gradient-to-br from-purple-500/30 to-blue-500/30 rounded-3xl flex items-center justify-center mb-8 border border-purple-400/40 shadow-[0_0_60px_rgba(168,85,247,0.4)]"
            >
              <Gamepad2 size={64} className="text-purple-200" />
            </motion.div>

            <h2 className="text-purple-100 text-xl mb-4 text-center">Jeu de Mémoire</h2>
            <p className="text-purple-300/60 text-sm text-center mb-8 max-w-xs">
              Mémorise et reproduis la séquence de couleurs. Plus tu progresses, plus tu gagnes de récompenses !
            </p>

            <button
              onClick={startGame}
              className="px-8 py-4 bg-gradient-to-r from-purple-500 to-blue-500 rounded-xl text-white shadow-[0_0_40px_rgba(168,85,247,0.5)] hover:shadow-[0_0_60px_rgba(168,85,247,0.7)] transition-all duration-300"
            >
              Commencer
            </button>
          </motion.div>
        )}

        {/* Playing State */}
        {gameState === 'playing' && (
          <motion.div
            key="playing"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="flex-1 flex flex-col"
          >
            {/* Score and Timer */}
            <div className="flex justify-between mb-8">
              <div className="flex items-center gap-2 bg-gradient-to-br from-purple-900/30 to-blue-900/30 px-4 py-2 rounded-xl border border-purple-400/30">
                <Trophy size={18} className="text-yellow-300" />
                <span className="text-purple-100">{score}</span>
              </div>

              <div className="flex items-center gap-2 bg-gradient-to-br from-purple-900/30 to-blue-900/30 px-4 py-2 rounded-xl border border-purple-400/30">
                <span className="text-purple-100">{timeLeft}s</span>
              </div>
            </div>

            {/* Game Grid */}
            <div className="flex-1 flex items-center justify-center">
              <div className="grid grid-cols-2 gap-4 max-w-sm w-full">
                {colors.map((color) => {
                  const isActive = activeButton === color.id;
                  
                  return (
                    <motion.button
                      key={color.id}
                      onClick={() => handleButtonClick(color.id)}
                      disabled={isShowingSequence}
                      className={`aspect-square rounded-3xl bg-gradient-to-br ${
                        isActive ? color.activeColor : color.color
                      } border-2 border-white/20 shadow-2xl transition-all duration-200 ${
                        isShowingSequence ? 'cursor-wait' : 'cursor-pointer'
                      }`}
                      whileHover={!isShowingSequence ? { scale: 1.05 } : {}}
                      whileTap={!isShowingSequence ? { scale: 0.95 } : {}}
                      animate={{
                        boxShadow: isActive
                          ? '0 0 60px rgba(168, 85, 247, 0.8)'
                          : '0 0 20px rgba(168, 85, 247, 0.3)',
                        scale: isActive ? 1.1 : 1,
                      }}
                      transition={{ duration: 0.2 }}
                    />
                  );
                })}
              </div>
            </div>

            {/* Status Text */}
            <div className="text-center py-4">
              <p className="text-purple-200">
                {isShowingSequence ? 'Observe la séquence...' : `Reproduis ${sequence.length} couleur${sequence.length > 1 ? 's' : ''}`}
              </p>
            </div>
          </motion.div>
        )}

        {/* Result State */}
        {gameState === 'result' && (
          <motion.div
            key="result"
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            className="flex-1 flex flex-col items-center justify-center"
          >
            <motion.div
              initial={{ scale: 0, rotate: -180 }}
              animate={{ scale: 1, rotate: 0 }}
              transition={{ type: 'spring', damping: 10 }}
              className="w-32 h-32 bg-gradient-to-br from-yellow-500/30 to-orange-500/30 rounded-3xl flex items-center justify-center mb-8 border border-yellow-400/40 shadow-[0_0_60px_rgba(251,191,36,0.6)]"
            >
              <Trophy size={64} className="text-yellow-300" />
            </motion.div>

            <motion.h2
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 }}
              className="text-purple-100 text-2xl mb-2"
            >
              Partie terminée !
            </motion.h2>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.4 }}
              className="text-center mb-8"
            >
              <p className="text-purple-300/60 text-sm mb-4">Score : {score}</p>
              
              <div className="flex gap-4 justify-center">
                <div className="flex items-center gap-2 bg-gradient-to-br from-yellow-500/20 to-orange-500/20 px-4 py-2 rounded-xl border border-yellow-400/30">
                  <span className="text-yellow-300">+{Math.floor(score / 2)} 🪙</span>
                </div>
                <div className="flex items-center gap-2 bg-gradient-to-br from-purple-500/20 to-blue-500/20 px-4 py-2 rounded-xl border border-purple-400/30">
                  <span className="text-purple-300">+{Math.floor(score / 5)} XP</span>
                </div>
              </div>
            </motion.div>

            <motion.button
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.5 }}
              onClick={resetGame}
              className="flex items-center gap-2 px-8 py-4 bg-gradient-to-r from-purple-500 to-blue-500 rounded-xl text-white shadow-[0_0_40px_rgba(168,85,247,0.5)] hover:shadow-[0_0_60px_rgba(168,85,247,0.7)] transition-all duration-300"
            >
              <RotateCcw size={20} />
              <span>Rejouer</span>
            </motion.button>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
