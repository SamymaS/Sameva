import { motion } from 'motion/react';

interface MagicParticlesProps {
  count?: number;
  color?: string;
  size?: number;
}

export function MagicParticles({ count = 30, color = 'white', size = 3 }: MagicParticlesProps) {
  return (
    <div className="absolute inset-0 pointer-events-none overflow-hidden">
      {Array.from({ length: count }).map((_, i) => {
        const randomX = Math.random() * 100;
        const randomDelay = Math.random() * 5;
        const randomDuration = 8 + Math.random() * 4;
        
        return (
          <motion.div
            key={i}
            className="absolute rounded-full"
            style={{
              left: `${randomX}%`,
              bottom: '-10px',
              width: `${size}px`,
              height: `${size}px`,
              backgroundColor: color,
              opacity: 0.2,
            }}
            animate={{
              y: [0, -window.innerHeight - 50],
              opacity: [0, 0.4, 0.2, 0],
              x: [0, (Math.random() - 0.5) * 50],
            }}
            transition={{
              duration: randomDuration,
              delay: randomDelay,
              repeat: Infinity,
              ease: 'linear',
            }}
          />
        );
      })}
    </div>
  );
}
