import { motion, HTMLMotionProps } from 'motion/react';
import { ReactNode } from 'react';

interface TouchableCardProps extends Omit<HTMLMotionProps<'div'>, 'onAnimationStart' | 'onDragStart' | 'onDragEnd' | 'onDrag'> {
  children: ReactNode;
  className?: string;
}

export function TouchableCard({ children, className = '', ...props }: TouchableCardProps) {
  return (
    <motion.div
      whileTap={{ scale: 0.98 }}
      transition={{ duration: 0.15, ease: 'easeInOut' }}
      className={`cursor-pointer touch-pan-y ${className}`}
      {...props}
    >
      {children}
    </motion.div>
  );
}
