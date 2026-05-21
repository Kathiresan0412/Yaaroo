export function BrandLogo({ className = "" }: { className?: string }) {
  return (
    <span className={`yaaro-logo ${className}`} aria-hidden="true">
      <img src="/brand-assets/logo.png" alt="" />
    </span>
  );
}
