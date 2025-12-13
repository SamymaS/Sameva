import { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { ChevronRight } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

interface OnboardingProps {
  onComplete: () => void;
}

const slides = [
  {
    title: 'Ton Aventure',
    description: 'Transforme tes tâches quotidiennes en quêtes épiques',
    image: 'https://images.unsplash.com/photo-1635075874856-dba5c46326da?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtYWdpY2FsJTIwYm9vayUyMGFuY2llbnR8ZW58MXx8fHwxNzY0ODUzMzYyfDA&ixlib=rb-4.1.0&q=80&w=1080',
    color: 'from-purple-500/20 to-blue-500/20',
  },
  {
    title: 'Tes Quêtes',
    description: 'Accomplis tes missions et gagne de l\'expérience',
    image: 'https://images.unsplash.com/photo-1618425977996-bebc5afe88f9?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtZWRpdGF0aW9uJTIwc3Bpcml0dWFsJTIwcGVhY2VmdWx8ZW58MXx8fHwxNzY0ODM5NjcwfDA&ixlib=rb-4.1.0&q=80&w=1080',
    color: 'from-blue-500/20 to-cyan-500/20',
  },
  {
    title: 'Ton Compagnon',
    description: 'Un familier t\'accompagnera dans ton voyage',
    image: 'https://images.unsplash.com/photo-1760012235279-d7d1ce4ba22b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxmYW50YXN5JTIwY29tcGFuaW9uJTIwY3JlYXR1cmV8ZW58MXx8fHwxNzY0ODUzMzYyfDA&ixlib=rb-4.1.0&q=80&w=1080',
    color: 'from-cyan-500/20 to-purple-500/20',
  },
];

export function Onboarding({ onComplete }: OnboardingProps) {
  const [currentSlide, setCurrentSlide] = useState(0);

  const handleNext = () => {
    if (currentSlide < slides.length - 1) {
      setCurrentSlide(prev => prev + 1);
    } else {
      onComplete();
    }
  };

  const handlePrevious = () => {
    if (currentSlide > 0) {
      setCurrentSlide(prev => prev - 1);
    }
  };

  return (
    <div className="relative w-full h-full bg-gradient-to-b from-[#2D2B55] to-[#0F172A] overflow-hidden">
      {/* Slides */}
      <div className="h-[60%] flex items-center justify-center p-6">
        <AnimatePresence mode="wait">
          <motion.div
            key={currentSlide}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            transition={{ duration: 0.5 }}
            className="w-full h-full flex items-center justify-center"
          >
            {/* Illustration avec Image réelle */}
            <motion.div
              animate={{ y: [0, -10, 0] }}
              transition={{
                duration: 3,
                repeat: Infinity,
                ease: 'easeInOut',
              }}
              className="relative w-full max-w-sm"
            >
              <div 
                className={`relative rounded-3xl overflow-hidden border-2 border-white/10 shadow-2xl bg-gradient-to-br ${slides[currentSlide].color}`}
                style={{ aspectRatio: '1' }}
              >
                <ImageWithFallback
                  src={slides[currentSlide].image}
                  alt={slides[currentSlide].title}
                  className="w-full h-full object-cover opacity-80"
                />
                {/* Overlay gradient */}
                <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />
              </div>
              
              {/* Glow effect */}
              <div 
                className="absolute inset-0 -m-4 rounded-3xl blur-2xl opacity-30"
                style={{
                  background: `linear-gradient(135deg, ${slides[currentSlide].color.replace('from-', '').split(' ')[0].replace('/', ' ')})`,
                }}
              />
            </motion.div>
          </motion.div>
        </AnimatePresence>
      </div>

      {/* Bottom Panel */}
      <div 
        className="absolute bottom-0 left-0 right-0 h-[40%] bg-[#1A202C] px-8 pt-8 pb-12"
        style={{
          borderTopLeftRadius: '40px',
          borderTopRightRadius: '40px',
        }}
      >
        <AnimatePresence mode="wait">
          <motion.div
            key={currentSlide}
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            transition={{ duration: 0.4 }}
          >
            <h2 className="text-white text-3xl text-center mb-4 font-fantasy">
              {slides[currentSlide].title}
            </h2>
            <p className="text-purple-200/70 text-center mb-8 text-lg">
              {slides[currentSlide].description}
            </p>
          </motion.div>
        </AnimatePresence>

        {/* Pagination Dots */}
        <div className="flex justify-center gap-2 mb-8">
          {slides.map((_, index) => (
            <motion.div
              key={index}
              className={`h-2 rounded-full transition-all duration-300 ${
                index === currentSlide
                  ? 'w-8 bg-[#4FD1C5]'
                  : 'w-2 bg-white/20'
              }`}
              animate={{
                scale: index === currentSlide ? 1 : 0.8,
              }}
            />
          ))}
        </div>

        {/* Buttons */}
        <div className="flex gap-4">
          {currentSlide > 0 && (
            <motion.button
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              onClick={handlePrevious}
              className="flex-1 h-14 rounded-full border-2 border-white/20 text-white font-semibold hover:bg-white/5 active:scale-95 transition-all duration-200"
            >
              Retour
            </motion.button>
          )}
          
          <button
            onClick={handleNext}
            className="flex-1 h-14 rounded-full bg-gradient-to-r from-[#4FD1C5] to-[#38B2AC] text-white font-semibold flex items-center justify-center gap-2 shadow-lg shadow-cyan-500/30 hover:shadow-cyan-500/50 active:scale-95 transition-all duration-200"
            style={{ minWidth: currentSlide === 0 ? '100%' : 'auto' }}
          >
            {currentSlide === slides.length - 1 ? 'Commencer l\'aventure' : 'Suivant'}
            <ChevronRight size={20} />
          </button>
        </div>
      </div>

      {/* Ambient glow */}
      <div className="absolute top-20 left-1/2 -translate-x-1/2 w-80 h-80 bg-purple-500/10 rounded-full blur-[100px] pointer-events-none" />
    </div>
  );
}