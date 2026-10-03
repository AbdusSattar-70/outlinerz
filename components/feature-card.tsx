import Image from "next/image";

interface FeatureCardProps {
  title: string;
  description: string;
  accent: string;
  photo?: string;
}

export function FeatureCard({
  title,
  description,
  accent,
  photo,
}: FeatureCardProps) {
  const hasPhoto = !!photo;

  return (
    <article
      className="group relative h-full overflow-hidden"
      style={!hasPhoto ? { backgroundColor: accent } : undefined}
    >
      {/* Background Image */}
      {hasPhoto && (
        <>
          <Image
            src={photo}
            alt={title}
            fill
            className="object-cover transition-transform duration-700 group-hover:scale-105"
          />

          {/* Itransition-like Overlay */}
          <div className="absolute inset-0 bg-black/45" />

          {/* Extra bottom gradient */}
          <div className="absolute inset-0 bg-linear-to-t from-black/80 via-black/20 to-transparent" />
        </>
      )}

      <div className="relative flex h-full flex-col justify-between p-8">
        <span className="text-xs uppercase tracking-[0.2em] text-white/80">
          Feature
        </span>

        <div>
          <h3 className="max-w-sm text-[28px] font-semibold leading-tight tracking-tight mb-4 text-white">
            {title}
          </h3>

          <p className="max-w-sm text-white/80">
            {description}
          </p>
        </div>
      </div>
    </article>
  );
}