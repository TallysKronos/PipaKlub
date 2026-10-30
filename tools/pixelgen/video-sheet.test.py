import importlib.util
from pathlib import Path
import unittest
from PIL import Image, ImageDraw

spec = importlib.util.spec_from_file_location('video_sheet', Path(__file__).with_name('video-to-sheet.py'))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class VideoSheetTests(unittest.TestCase):
    def test_chroma_is_binary_and_keeps_cyan_costume(self):
        image = Image.new('RGB', (3, 1))
        image.putdata([(255, 0, 255), (240, 20, 240), (40, 180, 180)])
        keyed = module.key_image(image)
        self.assertEqual(list(keyed.getchannel('A').getdata()), [0, 0, 255])

    def test_one_crop_preserves_bob_and_translation(self):
        images = []
        for x, y in [(30, 15), (36, 20)]:
            image = Image.new('RGB', (100, 100), '#ff00ff')
            ImageDraw.Draw(image).rectangle((x, y, x+12, y+50), fill='#284478')
            images.append(module.key_image(image))
        frames, indices, palette, alignment = module.pack(images, 48, 64, 16)
        self.assertEqual(len(palette), 2)
        self.assertGreater(frames[1].getbbox()[0], frames[0].getbbox()[0])
        self.assertGreater(frames[1].getbbox()[1], frames[0].getbbox()[1])
        self.assertEqual(len(indices[0]), 48*64)
        self.assertEqual(alignment['crop'], [30, 15, 49, 71])

    def test_palette_shared_and_no_fractional_alpha(self):
        a = Image.new('RGBA', (40, 50)); b = a.copy()
        ImageDraw.Draw(a).rectangle((5, 5, 30, 40), fill=(30, 100, 190, 255))
        ImageDraw.Draw(b).rectangle((5, 5, 30, 40), fill=(220, 120, 80, 255))
        frames, indices, palette, _ = module.pack([a, b], 32, 48, 2)
        self.assertLessEqual(len(palette), 3)
        for frame, ind in zip(frames, indices):
            self.assertEqual(set(frame.getchannel('A').getdata()), {0, 255})
            self.assertTrue(all(v < len(palette) for v in ind))
        self.assertNotEqual(set(indices[0]), set(indices[1]))

    def test_empty_frames_are_refused(self):
        with self.assertRaisesRegex(ValueError, 'Quadro vazio'):
            module.pack([Image.new('RGBA', (40, 50))])


if __name__ == '__main__':
    unittest.main()
