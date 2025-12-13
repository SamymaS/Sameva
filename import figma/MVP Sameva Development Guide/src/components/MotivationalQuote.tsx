import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Sparkles } from 'lucide-react';

const quotes = [
  {
    text: "La seule façon de faire du bon travail est d'aimer ce que vous faites",
    author: "Steve Jobs"
  },
  {
    text: "Le succès n'est pas final, l'échec n'est pas fatal : c'est le courage de continuer qui compte",
    author: "Winston Churchill"
  },
  {
    text: "Crois en toi-même et tout devient possible",
    author: "Proverbe"
  },
  {
    text: "Un voyage de mille lieues commence toujours par un premier pas",
    author: "Lao Tseu"
  },
  {
    text: "La motivation vous sert de départ. L'habitude vous fait continuer",
    author: "Jim Ryun"
  },
  {
    text: "Ce n'est pas la montagne que nous conquérons, mais nous-mêmes",
    author: "Edmund Hillary"
  },
  {
    text: "La différence entre l'ordinaire et l'extraordinaire, c'est ce petit effort supplémentaire",
    author: "Jimmy Johnson"
  },
  {
    text: "Le secret pour avancer est de commencer",
    author: "Mark Twain"
  },
  {
    text: "Chaque accomplissement commence par la décision d'essayer",
    author: "Gail Devers"
  },
  {
    text: "La vie est 10% ce qui vous arrive et 90% comment vous y réagissez",
    author: "Charles R. Swindoll"
  },
  {
    text: "Les rêves ne se réalisent pas par magie, il faut de la sueur, de la détermination et du travail",
    author: "Colin Powell"
  },
  {
    text: "Vous êtes plus courageux que vous ne le croyez, plus fort que vous ne le semblez",
    author: "A.A. Milne"
  },
  {
    text: "L'action est la clé fondamentale de tout succès",
    author: "Pablo Picasso"
  },
  {
    text: "Ne regardez pas l'horloge, faites comme elle : avancez",
    author: "Sam Levenson"
  },
  {
    text: "Votre seule limite, c'est vous",
    author: "Proverbe"
  },
  {
    text: "Les champions sont faits de quelque chose qu'ils ont au fond d'eux - un désir, un rêve, une vision",
    author: "Muhammad Ali"
  },
  {
    text: "Le meilleur moment pour planter un arbre était il y a 20 ans. Le second meilleur moment est maintenant",
    author: "Proverbe chinois"
  },
  {
    text: "Tout ce que vous avez toujours voulu se trouve de l'autre côté de la peur",
    author: "George Addair"
  },
  {
    text: "La persévérance est la clé du succès",
    author: "Proverbe japonais"
  },
  {
    text: "Commence là où tu es. Utilise ce que tu as. Fais ce que tu peux",
    author: "Arthur Ashe"
  }
];

export function MotivationalQuote() {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [direction, setDirection] = useState(1);

  useEffect(() => {
    // Rotation toutes les 8 secondes
    const interval = setInterval(() => {
      setDirection(1);
      setCurrentIndex((prev) => (prev + 1) % quotes.length);
    }, 8000);

    return () => clearInterval(interval);
  }, []);

  const currentQuote = quotes[currentIndex];

  const variants = {
    enter: (direction: number) => ({
      x: direction > 0 ? 20 : -20,
      opacity: 0,
      scale: 0.95
    }),
    center: {
      x: 0,
      opacity: 1,
      scale: 1
    },
    exit: (direction: number) => ({
      x: direction < 0 ? 20 : -20,
      opacity: 0,
      scale: 0.95
    })
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6, delay: 0.3 }}
      className="relative mb-3 overflow-hidden"
    >
      <div className="relative p-3 bg-gradient-to-br from-purple-900/20 via-indigo-900/20 to-blue-900/20 rounded-2xl border border-purple-400/20 shadow-[0_8px_32px_rgba(139,92,246,0.15)] backdrop-blur-sm">
        {/* Decorative sparkle icon */}
        <div className="absolute top-2.5 left-2.5 w-7 h-7 rounded-full bg-purple-500/10 flex items-center justify-center border border-purple-400/20">
          <Sparkles size={12} className="text-purple-300/70" />
        </div>

        {/* Animated glow effect */}
        <motion.div
          className="absolute inset-0 bg-gradient-to-r from-transparent via-purple-400/5 to-transparent pointer-events-none rounded-2xl"
          animate={{
            x: ['-100%', '200%'],
          }}
          transition={{
            duration: 4,
            repeat: Infinity,
            repeatDelay: 3,
            ease: 'easeInOut',
          }}
        />

        {/* Quote content */}
        <div className="relative pl-5 pr-2 min-h-[60px] flex flex-col justify-center">
          <AnimatePresence mode="wait" custom={direction}>
            <motion.div
              key={currentIndex}
              custom={direction}
              variants={variants}
              initial="enter"
              animate="center"
              exit="exit"
              transition={{
                x: { type: 'spring', stiffness: 300, damping: 30 },
                opacity: { duration: 0.4 },
                scale: { duration: 0.4 }
              }}
            >
              <p className="text-purple-100/90 text-xs leading-relaxed mb-1.5 italic line-clamp-2">
                "{currentQuote.text}"
              </p>
              <p className="text-purple-300/50 text-xs">
                — {currentQuote.author}
              </p>
            </motion.div>
          </AnimatePresence>
        </div>

        {/* Progress indicator dots */}
        <div className="flex justify-center gap-1.5 mt-2">
          {quotes.slice(0, 5).map((_, index) => {
            const isActive = index === currentIndex % 5;
            return (
              <motion.div
                key={index}
                className={`h-1 rounded-full transition-all duration-300 ${
                  isActive ? 'w-6 bg-purple-400/60' : 'w-1 bg-purple-400/20'
                }`}
                animate={{
                  scale: isActive ? 1 : 0.8,
                }}
              />
            );
          })}
        </div>

        {/* Floating particles - REDUCED */}
        {Array.from({ length: 2 }).map((_, i) => (
          <motion.div
            key={i}
            className="absolute w-1 h-1 bg-purple-300/30 rounded-full"
            style={{
              left: `${20 + i * 40}%`,
              top: `${30 + i * 20}%`,
            }}
            animate={{
              y: [0, -8, 0],
              opacity: [0.2, 0.5, 0.2],
              scale: [0.8, 1.2, 0.8],
            }}
            transition={{
              duration: 3 + i,
              repeat: Infinity,
              delay: i * 0.7,
              ease: 'easeInOut',
            }}
          />
        ))}
      </div>
    </motion.div>
  );
}