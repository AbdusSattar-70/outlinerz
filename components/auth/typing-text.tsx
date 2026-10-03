"use client";

import { useEffect, useState } from "react";
import { GiPencil } from "react-icons/gi";
import { FaEraser } from "react-icons/fa";
import { SENTENCES } from "@/lib/constants";

type Phase = "typing" | "pause" | "erasing";

const TYPE_SPEED = 120;
const ERASE_SPEED = 50;
const PAUSE_TIME = 2500;

export function TypingText() {
  const [sentenceIndex, setSentenceIndex] = useState(0);
  const [charIndex, setCharIndex] = useState(0);
  const [phase, setPhase] = useState<Phase>("typing");

  const sentence = SENTENCES[sentenceIndex];
  const text = sentence.slice(0, charIndex);

  useEffect(() => {
    let timer: ReturnType<typeof setTimeout>;

    if (phase === "typing") {
      if (charIndex < sentence.length) {
        timer = setTimeout(() => {
          setCharIndex((prev) => prev + 1);
        }, TYPE_SPEED);
      } else {
        timer = setTimeout(() => {
          setPhase("pause");
        }, 300);
      }
    }

    if (phase === "pause") {
      timer = setTimeout(() => {
        setPhase("erasing");
      }, PAUSE_TIME);
    }

    if (phase === "erasing") {
      if (charIndex > 0) {
        timer = setTimeout(() => {
          setCharIndex((prev) => prev - 1);
        }, ERASE_SPEED);
      } else {
        timer = setTimeout(() => {
          setSentenceIndex(
            (prev) => (prev + 1) % SENTENCES.length
          );
          setPhase("typing");
        }, 300);
      }
    }

    return () => clearTimeout(timer);
  }, [phase, charIndex, sentence]);

  return (
    <div
      className="mt-4 flex items-center text-[#d292ff] text-lg font-medium min-h-10"
      aria-live="polite"
    >
      <span>{text}</span>

      {phase === "typing" && (
        <span className="ml-1 animate-bounce">
          <GiPencil size={26} />
        </span>
      )}

      {phase === "erasing" && (
        <span className="ml-1">
          <FaEraser size={22} />
        </span>
      )}
    </div>
  );
}