export function SkeletonCard() {
  return (
    <div className="flex items-center justify-center h-screen bg-background text-white">
      <div className="relative w-60 h-60">
        {/* Spinning Outer Border */}
        <div
          className="absolute inset-0 rounded-full border-30 border-t-blue-500 border-r-violet-500 border-b-green-500 border-l-yellow-400 animate-spin
  bg-white/5 backdrop-blur-sm shadow-md shadow-black/10"
        />

        {/* Centered Logo */}
        <div className="absolute inset-0 flex flex-col items-center justify-center text-center">
          <div className="flex items-center space-x-2">
            <span className="text-xl font-semibold bg-linear-to-r from-blue-500 to-violet-600 bg-clip-text text-transparent hidden sm:inline">
              Sohoj Academy
            </span>
          </div>
          <p className="text-xs mt-1 text-gray-300 italic">
            Learning <span className="not-italic text-white">Made</span> Easy & Fun
          </p>
        </div>
      </div>
    </div>
  );
}
