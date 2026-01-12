import { useState } from 'react';
import { motion } from 'motion/react';
import { Bell, Volume2, Moon, Smartphone, Globe, Shield, LogOut, ChevronRight } from 'lucide-react';
import type { UserData } from '../App';

interface SettingsProps {
  userData: UserData;
}

interface SettingToggle {
  id: string;
  label: string;
  icon: React.ElementType;
  enabled: boolean;
}

export function Settings({ userData }: SettingsProps) {
  const [settings, setSettings] = useState<SettingToggle[]>([
    { id: 'notifications', label: 'Notifications', icon: Bell, enabled: true },
    { id: 'sound', label: 'Sons & Musique', icon: Volume2, enabled: true },
    { id: 'darkMode', label: 'Mode Nocturne', icon: Moon, enabled: true },
    { id: 'haptic', label: 'Vibrations', icon: Smartphone, enabled: false },
  ]);

  const toggleSetting = (id: string) => {
    setSettings(prev => prev.map(setting => 
      setting.id === id ? { ...setting, enabled: !setting.enabled } : setting
    ));
  };

  return (
    <div className="h-full flex flex-col px-4 pt-6 pb-24 overflow-y-auto">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="mb-6"
      >
        <h1 className="text-cream-100 text-2xl tracking-wide mb-1 font-fantasy">Paramètres</h1>
        <p className="text-purple-300/60 text-sm">Personnalise ton expérience</p>
      </motion.div>

      {/* Preferences Section */}
      <div className="mb-6">
        <h2 className="text-purple-200 text-sm font-semibold mb-3 uppercase tracking-wider">Préférences</h2>
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.1 }}
          className="space-y-3"
        >
          {settings.map((setting, index) => {
            const Icon = setting.icon;
            return (
              <motion.div
                key={setting.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.4, delay: 0.15 + index * 0.05 }}
                className="flex items-center justify-between p-4 bg-gradient-to-r from-purple-900/30 to-blue-900/30 rounded-2xl border border-purple-400/20 backdrop-blur-sm"
              >
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-purple-500/20 rounded-xl">
                    <Icon size={18} className="text-purple-300" />
                  </div>
                  <span className="text-white">{setting.label}</span>
                </div>

                {/* Toggle Switch */}
                <button
                  onClick={() => toggleSetting(setting.id)}
                  className={`relative w-[50px] h-7 rounded-full transition-all duration-300 ${
                    setting.enabled
                      ? 'bg-gradient-to-r from-[#4FD1C5] to-[#38B2AC]'
                      : 'bg-[#4A5568]'
                  }`}
                >
                  <motion.div
                    className="absolute top-1 w-5 h-5 bg-white rounded-full shadow-lg"
                    animate={{
                      left: setting.enabled ? '26px' : '4px',
                    }}
                    transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                  />
                </button>
              </motion.div>
            );
          })}
        </motion.div>
      </div>

      {/* General Section */}
      <div className="mb-6">
        <h2 className="text-purple-200 text-sm font-semibold mb-3 uppercase tracking-wider">Général</h2>
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.3 }}
          className="space-y-3"
        >
          <button className="w-full flex items-center justify-between p-4 bg-gradient-to-r from-purple-900/30 to-blue-900/30 rounded-2xl border border-purple-400/20 backdrop-blur-sm hover:border-purple-400/40 active:scale-98 transition-all duration-300">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-500/20 rounded-xl">
                <Globe size={18} className="text-purple-300" />
              </div>
              <div className="text-left">
                <p className="text-white">Langue</p>
                <p className="text-purple-300/60 text-xs">Français</p>
              </div>
            </div>
            <ChevronRight size={18} className="text-purple-400" />
          </button>

          <button className="w-full flex items-center justify-between p-4 bg-gradient-to-r from-purple-900/30 to-blue-900/30 rounded-2xl border border-purple-400/20 backdrop-blur-sm hover:border-purple-400/40 active:scale-98 transition-all duration-300">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-500/20 rounded-xl">
                <Shield size={18} className="text-purple-300" />
              </div>
              <div className="text-left">
                <p className="text-white">Confidentialité</p>
                <p className="text-purple-300/60 text-xs">Gérer tes données</p>
              </div>
            </div>
            <ChevronRight size={18} className="text-purple-400" />
          </button>
        </motion.div>
      </div>

      {/* About Section */}
      <div className="mb-6">
        <h2 className="text-purple-200 text-sm font-semibold mb-3 uppercase tracking-wider">À propos</h2>
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.4 }}
          className="p-4 bg-gradient-to-r from-purple-900/30 to-blue-900/30 rounded-2xl border border-purple-400/20 backdrop-blur-sm"
        >
          <div className="text-center mb-4">
            <h3 className="text-white text-xl font-fantasy mb-1">SAMEVA</h3>
            <p className="text-purple-300/60 text-sm">Version 1.0.0 (MVP)</p>
          </div>
          
          <div className="space-y-2 text-center">
            <button className="text-purple-300 text-sm hover:text-purple-200 transition-colors">
              Conditions d'utilisation
            </button>
            <span className="text-purple-500/40 mx-2">•</span>
            <button className="text-purple-300 text-sm hover:text-purple-200 transition-colors">
              Politique de confidentialité
            </button>
          </div>
        </motion.div>
      </div>

      {/* Logout Button */}
      <motion.button
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.5 }}
        className="w-full h-14 rounded-full bg-gradient-to-r from-red-500/20 to-pink-500/20 border-2 border-red-400/30 text-red-300 font-semibold flex items-center justify-center gap-2 hover:bg-red-500/30 active:scale-95 transition-all duration-300"
      >
        <LogOut size={20} />
        <span>Déconnexion</span>
      </motion.button>
    </div>
  );
}