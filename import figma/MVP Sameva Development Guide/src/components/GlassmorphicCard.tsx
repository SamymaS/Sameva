import { ReactNode } from 'react';

interface GlassmorphicCardProps {
  children: ReactNode;
  className?: string;
  padding?: string;
}

export function GlassmorphicCard({ 
  children, 
  className = '', 
  padding = 'p-8' 
}: GlassmorphicCardProps) {
  return (
    <div 
      className={`glass rounded-3xl ${padding} ${className}`}
      style={{
        background: 'rgba(255, 255, 255, 0.1)',
        backdropFilter: 'blur(20px)',
        WebkitBackdropFilter: 'blur(20px)',
        border: '1px solid rgba(255, 255, 255, 0.2)',
      }}
    >
      {children}
    </div>
  );
}
