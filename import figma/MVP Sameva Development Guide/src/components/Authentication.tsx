import { useState } from 'react';
import { motion } from 'motion/react';
import { Mail, Lock, Eye, EyeOff } from 'lucide-react';
import { GlassmorphicCard } from './GlassmorphicCard';
import { MagicParticles } from './MagicParticles';

interface AuthenticationProps {
  onLogin: () => void;
}

export function Authentication({ onLogin }: AuthenticationProps) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isSignUp, setIsSignUp] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Simulate login
    onLogin();
  };

  return (
    <div className="relative w-full h-full bg-gradient-to-b from-[#2D2B55] via-[#1a1449] to-[#0F172A] overflow-hidden flex items-center justify-center p-6">
      {/* Background particles */}
      <MagicParticles count={20} color="rgba(79, 209, 197, 0.3)" size={2} />
      
      {/* Ambient glows */}
      <div className="absolute top-20 right-10 w-72 h-72 bg-purple-500/20 rounded-full blur-[120px] animate-pulse-glow" />
      <div className="absolute bottom-20 left-10 w-80 h-80 bg-cyan-500/15 rounded-full blur-[120px] animate-pulse-glow" style={{ animationDelay: '1s' }} />

      {/* Auth Card */}
      <motion.div
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.6, ease: 'easeOut' }}
        className="w-full max-w-md relative z-10"
      >
        <GlassmorphicCard>
          {/* Logo/Title */}
          <div className="text-center mb-8">
            <h1 className="font-fantasy text-4xl text-white mb-2">SAMEVA</h1>
            <p className="text-purple-200/60 text-sm">
              {isSignUp ? 'Crée ton compte' : 'Bienvenue, Voyageur'}
            </p>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Email Input */}
            <div className="relative">
              <div className="absolute left-4 top-1/2 -translate-y-1/2 text-purple-300/50">
                <Mail size={20} />
              </div>
              <input
                type="email"
                placeholder="Email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full h-[50px] bg-[#0F172A]/50 border border-[#4A5568] rounded-xl pl-12 pr-4 text-white placeholder:text-purple-300/30 focus:border-[#4FD1C5] focus:shadow-[0_0_15px_rgba(79,209,197,0.3)] outline-none transition-all duration-300"
              />
            </div>

            {/* Password Input */}
            <div className="relative">
              <div className="absolute left-4 top-1/2 -translate-y-1/2 text-purple-300/50">
                <Lock size={20} />
              </div>
              <input
                type={showPassword ? 'text' : 'password'}
                placeholder="Mot de passe"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full h-[50px] bg-[#0F172A]/50 border border-[#4A5568] rounded-xl pl-12 pr-12 text-white placeholder:text-purple-300/30 focus:border-[#4FD1C5] focus:shadow-[0_0_15px_rgba(79,209,197,0.3)] outline-none transition-all duration-300"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-4 top-1/2 -translate-y-1/2 text-purple-300/50 hover:text-purple-300 transition-colors"
              >
                {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
              </button>
            </div>

            {/* Submit Button */}
            <motion.button
              type="submit"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              className="w-full h-14 rounded-full bg-gradient-to-r from-[#4FD1C5] to-[#38B2AC] text-white font-semibold shadow-lg shadow-cyan-500/30 hover:shadow-cyan-500/50 transition-all duration-300"
            >
              {isSignUp ? 'S\'inscrire' : 'Se connecter'}
            </motion.button>

            {/* Divider */}
            <div className="flex items-center gap-4 my-6">
              <div className="flex-1 h-px bg-white/10" />
              <span className="text-purple-300/40 text-sm">OU</span>
              <div className="flex-1 h-px bg-white/10" />
            </div>

            {/* Google Button */}
            <button
              type="button"
              className="w-full h-14 rounded-full bg-white text-[#2D3748] font-semibold flex items-center justify-center gap-3 shadow-lg hover:shadow-xl transition-all duration-300 active:scale-98"
            >
              <svg width="20" height="20" viewBox="0 0 24 24">
                <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
              </svg>
              Continuer avec Google
            </button>

            {/* Toggle Sign Up / Sign In */}
            <p className="text-center text-purple-200/60 text-sm mt-6">
              {isSignUp ? 'Déjà un compte ?' : 'Pas encore de compte ?'}{' '}
              <button
                type="button"
                onClick={() => setIsSignUp(!isSignUp)}
                className="text-[#4FD1C5] hover:text-[#38B2AC] font-semibold transition-colors"
              >
                {isSignUp ? 'Se connecter' : 'S\'inscrire'}
              </button>
            </p>
          </form>
        </GlassmorphicCard>
      </motion.div>
    </div>
  );
}
