import { motion } from 'motion/react';
import { RunicLoader } from './RunicLoader';
import { MagicParticles } from './MagicParticles';

export function SplashScreen() {
  return (
    <div className="relative w-full h-full bg-gradient-to-b from-[#2D2B55] to-[#0F172A] flex flex-col items-center justify-center overflow-hidden">
      {/* Background particles */}
      <MagicParticles count={25} color="rgba(255, 255, 255, 0.3)" size={3} />
      
      {/* Logo */}
      <motion.div
        initial={{ opacity: 0, scale: 0.8 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.8, ease: 'easeOut' }}
        className="relative z-10 mb-12"
      >
        <motion.div
          animate={{ scale: [1, 1.05, 1] }}
          transition={{
            duration: 3,
            repeat: Infinity,
            ease: 'easeInOut',
          }}
          className="relative"
          style={{
            filter: 'drop-shadow(0px 0px 20px rgba(79, 209, 197, 0.4))',
          }}
        >
          <h1 
            className="font-fantasy text-7xl text-white tracking-wider"
            style={{
              textShadow: '0 0 30px rgba(128, 90, 213, 0.6)',
            }}
          >
            SAMEVA
          </h1>
        </motion.div>
        
        {/* Subtitle */}
        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.5, duration: 1 }}
          className="text-center text-purple-200/60 text-sm tracking-widest mt-2"
        >
          TON AVENTURE COMMENCE
        </motion.p>
      </motion.div>
      
      {/* Loader */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.8, duration: 0.5 }}
        className="absolute bottom-20"
      >
        <RunicLoader size={64} />
      </motion.div>
      
      {/* Ambient glow */}
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 w-96 h-96 bg-purple-500/20 rounded-full blur-[120px] animate-pulse-glow" />
    </div>
  );
}
