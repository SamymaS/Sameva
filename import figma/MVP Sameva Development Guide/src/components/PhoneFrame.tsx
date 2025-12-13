import { ReactNode, useState } from 'react';

interface PhoneFrameProps {
  children: ReactNode;
}

export function PhoneFrame({ children }: PhoneFrameProps) {
  const [deviceType, setDeviceType] = useState<'ios' | 'android'>('ios');

  return (
    <div className="min-h-screen w-full bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 p-4 md:p-8">
      {/* Device selector buttons - Outside phone */}
      <div className="flex justify-center gap-3 mb-6">
        <button
          onClick={() => setDeviceType('ios')}
          className={`px-6 py-2.5 rounded-full transition-all duration-300 ${
            deviceType === 'ios'
              ? 'bg-gradient-to-r from-purple-500 to-blue-500 text-white shadow-lg shadow-purple-500/30'
              : 'bg-white/10 text-white/60 hover:bg-white/20 backdrop-blur-sm border border-white/20'
          }`}
        >
          iPhone 15 Pro
        </button>
        <button
          onClick={() => setDeviceType('android')}
          className={`px-6 py-2.5 rounded-full transition-all duration-300 ${
            deviceType === 'android'
              ? 'bg-gradient-to-r from-green-500 to-emerald-500 text-white shadow-lg shadow-green-500/30'
              : 'bg-white/10 text-white/60 hover:bg-white/20 backdrop-blur-sm border border-white/20'
          }`}
        >
          Android Flagship
        </button>
      </div>

      {/* Phone container with 3D effect */}
      <div className="flex items-center justify-center">
        <div className="relative" style={{ 
          perspective: '2000px',
          filter: 'drop-shadow(0 25px 50px rgba(0, 0, 0, 0.5))'
        }}>
        {/* Phone device */}
        <div 
          className="relative bg-black rounded-[3rem] p-3 transition-transform duration-300 hover:scale-[1.02]"
          style={{
            width: '375px',
            height: '812px',
            boxShadow: `
              inset 0 0 6px rgba(255, 255, 255, 0.15),
              0 0 0 1px rgba(255, 255, 255, 0.1),
              0 20px 60px rgba(0, 0, 0, 0.4)
            `
          }}
        >
          {/* Side buttons - Volume */}
          <div className="absolute -left-[3px] top-[120px] w-[3px] h-[32px] bg-slate-800 rounded-l-sm" />
          <div className="absolute -left-[3px] top-[170px] w-[3px] h-[32px] bg-slate-800 rounded-l-sm" />
          <div className="absolute -left-[3px] top-[210px] w-[3px] h-[60px] bg-slate-800 rounded-l-sm" />
          
          {/* Side button - Power */}
          <div className="absolute -right-[3px] top-[180px] w-[3px] h-[70px] bg-slate-800 rounded-r-sm" />

          {/* Screen */}
          <div className="relative w-full h-full bg-white rounded-[2.6rem] overflow-hidden">
            {/* Dynamic Island / Notch - with safe padding for content below */}
            <div className="absolute top-0 left-1/2 -translate-x-1/2 z-[100] w-[126px] h-[37px] bg-black rounded-b-[1.2rem] flex items-center justify-center gap-2 pointer-events-none">
              {/* Camera */}
              <div className="w-[10px] h-[10px] bg-slate-900 rounded-full border border-slate-700" />
              {/* Sensors */}
              <div className="w-[50px] h-[6px] bg-slate-900 rounded-full" />
            </div>

            {/* App content - with padding for notch */}
            <div className="w-full h-full overflow-hidden" style={{ paddingTop: '40px' }}>
              {children}
            </div>
          </div>

          {/* Reflection effect */}
          <div 
            className="absolute inset-0 rounded-[3rem] pointer-events-none"
            style={{
              background: 'linear-gradient(135deg, rgba(255,255,255,0.1) 0%, transparent 50%, rgba(255,255,255,0.05) 100%)'
            }}
          />
        </div>

        {/* Ambient glow */}
        <div 
          className="absolute inset-0 rounded-[3rem] blur-2xl opacity-30 -z-10"
          style={{
            background: deviceType === 'ios' 
              ? 'linear-gradient(135deg, #6366f1 0%, #8b5cf6 50%, #ec4899 100%)'
              : 'linear-gradient(135deg, #10b981 0%, #059669 50%, #047857 100%)'
          }}
        />
      </div>
      </div>
    </div>
  );
}