import { ReactNode } from 'react';

export type Rarity = 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary' | 'mythic';

interface RarityBorderProps {
  rarity: Rarity;
  children: ReactNode;
  className?: string;
  withGlow?: boolean;
}

const rarityStyles: Record<Rarity, string> = {
  common: 'border-2 border-[#CBD5E0]',
  uncommon: 'border-2 border-[#68D391]',
  rare: 'border-2 border-[#4299E1]',
  epic: 'border-2 border-[#9F7AEA] shadow-[0_0_15px_rgba(159,122,234,0.6)]',
  legendary: 'border-2 border-[#ECC94B] shadow-[0_0_20px_rgba(236,201,75,0.8)]',
  mythic: 'border-2 border-[#FC8181] shadow-[0_0_25px_rgba(252,129,129,0.9)]',
};

const glowStyles: Record<Rarity, string> = {
  common: '',
  uncommon: '',
  rare: '',
  epic: 'after:absolute after:inset-0 after:bg-gradient-to-br after:from-purple-400/10 after:to-transparent after:pointer-events-none after:rounded-inherit',
  legendary: 'after:absolute after:inset-0 after:bg-gradient-to-br after:from-yellow-400/20 after:to-transparent after:pointer-events-none after:rounded-inherit animate-pulse-glow',
  mythic: 'after:absolute after:inset-0 after:bg-gradient-to-br after:from-red-400/30 after:to-black/20 after:pointer-events-none after:rounded-inherit animate-pulse-glow',
};

export function RarityBorder({ rarity, children, className = '', withGlow = true }: RarityBorderProps) {
  const rarityClass = rarityStyles[rarity];
  const glowClass = withGlow ? glowStyles[rarity] : '';
  
  return (
    <div className={`relative ${rarityClass} ${glowClass} ${className}`}>
      {children}
    </div>
  );
}
